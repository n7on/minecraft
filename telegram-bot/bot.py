#!/usr/bin/env python3
"""Telegram <-> Claude Code bridge for admin'ing the Minecraft server.

Two access tiers, keyed by Telegram user ID:

- ADMIN_USER_IDS: full control. Each message runs `claude -p` with
  bot-settings.json's allow/deny list. Anything not explicitly allowed is
  auto-denied (no human to prompt); a denial is surfaced as a yes/no
  confirmation ask, and "yes" resumes the same session with
  --permission-mode bypassPermissions for that one turn to complete it.
- READONLY_USER_IDS: information only. Runs with --tools Read,Glob,Grep,
  which removes Bash/Edit/Write from the session entirely -- there is no
  shell to chain commands in, so this can't be escalated no matter what's
  asked (a narrow Bash allow-list alone isn't enough: pattern matching is a
  prefix match on the whole command string, so e.g. an allow-list for
  "echo *" still lets "echo hi && whoami" run -- verified empirically).
"""
import json
import os
import shutil
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path

BOT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = os.environ.get("PROJECT_DIR", str(BOT_DIR.parent))
CLAUDE_BIN = os.environ.get("CLAUDE_BIN") or shutil.which("claude") or str(Path.home() / ".local/bin/claude")
BOT_TOKEN = os.environ["BOT_TOKEN"]
ADMIN_USER_IDS = {int(x) for x in os.environ.get("ALLOWED_USER_IDS", "").split(",") if x.strip()}
READONLY_USER_IDS = {int(x) for x in os.environ.get("READONLY_USER_IDS", "").split(",") if x.strip()}
SETTINGS_FILE = str(BOT_DIR / "bot-settings.json")
STATE_FILE = BOT_DIR / "state.json"
LOG_FILE = BOT_DIR / "bot.log"
API_BASE = f"https://api.telegram.org/bot{BOT_TOKEN}"

AFFIRM = {"yes", "y", "confirm", "go ahead", "do it", "proceed"}
DENY = {"no", "n", "cancel", "stop", "don't", "dont"}

ADMIN_SYSTEM_PROMPT = (
    "You are controlling a docker-compose Minecraft server (itzg/minecraft-server) "
    "for the admin's son and his friends, via Telegram messages from the admin. "
    "The project directory (docker-compose.yml, README.md) is your working directory. "
    "The world data, server jar, plugins, cache and logs live under data/ and are "
    "gitignored runtime state. If a command you tried is blocked by permissions, "
    "clearly tell the admin what you wanted to run and why, so they can decide. "
    "Keep replies short and plain text (this is a Telegram chat, sent with no markdown "
    "parsing): no asterisks, headers, or backticks for formatting. If you edit docker-compose.yml, briefly "
    "say what changed and that 'docker compose up -d' is needed to apply it (you can "
    "run that yourself).\n\n"
    "For casual questions about what's happening in-game (is anyone on, is there a mob "
    "farm running, where's a player, etc.), budget at most about a minute of tool use: "
    "use one or two targeted rcon-cli commands (e.g. 'list', 'data get entity <player> "
    "Pos') and answer with whatever that tells you. Do not loop over every mob type "
    "across every dimension, do not write a custom parser for the world save files "
    "(region/NBT format) to scan chunks -- that's slow, expensive, and not what a chat "
    "answer needs. If there's no fast way to check something precisely, just say so and "
    "give your best guess from what you can see quickly, rather than spending minutes on "
    "an exhaustive investigation. Only go deep if the admin explicitly asks for a "
    "thorough investigation.\n\n"
    "If asked for a plugin that needs real code (custom commands, GUIs, event handling, "
    "persistent data -- anything a datapack's JSON recipes/loot tables can't do), use "
    "custom-plugins/: copy custom-plugins/_template/ to a new custom-plugins/<name>/, "
    "write the Java there, then run custom-plugins/build.sh <name> to compile it (via a "
    "Maven+Java 25 container, no local toolchain needed) and drop the jar into "
    "data/plugins/. See custom-plugins/README.md for the exact steps. A full server "
    "restart is needed to load a new plugin jar."
)

READONLY_SYSTEM_PROMPT = (
    "You are answering questions about a docker-compose Minecraft server "
    "(itzg/minecraft-server) for one of the players' friends, via Telegram. You have "
    "read-only file access to the project directory: docker-compose.yml (settings, "
    "plugins), README.md, and data/logs/ (server logs) -- no shell, no edit/write, no "
    "ability to change anything, so nothing you do can affect the server. Use this to "
    "answer things like current settings, recent errors, how to join, who's "
    "whitelisted, etc. If asked to change something, restart the server, or run a "
    "command, say plainly that you don't have permission for that and they should ask "
    "an admin instead -- don't imply you did something you didn't. Keep replies short "
    "and plain text (Telegram chat, no markdown formatting)."
)


def log(msg):
    line = f"{time.strftime('%Y-%m-%d %H:%M:%S')} {msg}\n"
    with open(LOG_FILE, "a") as f:
        f.write(line)
    print(line, end="")


def load_state():
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {}


def save_state(state):
    STATE_FILE.write_text(json.dumps(state, indent=2))


def api_call(method, params, timeout=35):
    url = f"{API_BASE}/{method}"
    data = json.dumps(params).encode()
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        body = json.loads(resp.read())
    if not body.get("ok"):
        raise RuntimeError(f"Telegram API {method} returned not-ok: {body}")
    return body


def send_message(chat_id, text):
    text = text or "(no response)"
    for i in range(0, len(text), 4000):
        chunk = text[i:i + 4000]
        try:
            api_call("sendMessage", {"chat_id": chat_id, "text": chunk})
        except urllib.error.HTTPError as e:
            log(f"sendMessage failed: HTTP {e.code} body={e.read()[:500]!r}")
        except Exception as e:
            log(f"sendMessage failed: {e!r}")


TIMEOUT_SECONDS = 900
TYPING_INTERVAL_SECONDS = 4


def run_claude(prompt, session_id=None, bypass=False, readonly=False, chat_id=None):
    cmd = [CLAUDE_BIN, "-p", prompt, "--output-format", "json"]
    if readonly:
        cmd += ["--tools", "Read,Glob,Grep", "--append-system-prompt", READONLY_SYSTEM_PROMPT,
                "--permission-mode", "dontAsk", "--permission-prompts", "none"]
    else:
        cmd += ["--settings", SETTINGS_FILE, "--append-system-prompt", ADMIN_SYSTEM_PROMPT]
        if bypass:
            cmd += ["--permission-mode", "bypassPermissions"]
        else:
            cmd += ["--permission-mode", "dontAsk", "--permission-prompts", "none"]
    if session_id:
        cmd += ["--resume", session_id]

    log(f"-> session={session_id} bypass={bypass} prompt={prompt!r}")
    proc = subprocess.Popen(cmd, cwd=PROJECT_DIR, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    start = time.time()
    last_typing = 0
    stdout = stderr = ""
    while True:
        if chat_id and time.time() - last_typing >= TYPING_INTERVAL_SECONDS:
            try:
                api_call("sendChatAction", {"chat_id": chat_id, "action": "typing"})
            except Exception as e:
                log(f"sendChatAction failed: {e!r}")
            last_typing = time.time()
        try:
            stdout, stderr = proc.communicate(timeout=TYPING_INTERVAL_SECONDS)
            break
        except subprocess.TimeoutExpired:
            if time.time() - start > TIMEOUT_SECONDS:
                proc.kill()
                proc.communicate()
                log("claude invocation timed out")
                return {"result": "Timed out waiting for Claude.", "session_id": session_id, "permission_denials": []}

    if proc.returncode != 0:
        log(f"claude exited {proc.returncode}: {stderr[-2000:]}")
        return {"result": f"Internal error (exit {proc.returncode}). Check bot.log.",
                "session_id": session_id, "permission_denials": []}
    try:
        data = json.loads(stdout)
    except json.JSONDecodeError:
        log(f"bad json from claude: {stdout[-2000:]}")
        return {"result": "Internal error: couldn't parse Claude's response.",
                "session_id": session_id, "permission_denials": []}
    log(f"<- session={data.get('session_id')} denials={len(data.get('permission_denials') or [])} "
        f"cost=${data.get('total_cost_usd')}")
    return data


def describe_denials(denials):
    lines = []
    for d in denials:
        ti = d.get("tool_input", {})
        detail = ti.get("command") or ti.get("file_path") or str(ti)
        lines.append(f"- {d.get('tool_name')}: {detail}")
    return "\n".join(lines)


def handle_message(chat_id, user_id, text, state):
    if user_id in ADMIN_USER_IDS:
        tier = "admin"
    elif user_id in READONLY_USER_IDS:
        tier = "readonly"
    else:
        log(f"UNAUTHORIZED user_id={user_id} chat_id={chat_id} text={text!r}")
        send_message(chat_id, "Not authorized.")
        return

    chat_key = str(chat_id)
    chat_state = state.get(chat_key, {"session_id": None, "pending": False})
    normalized = text.strip().lower()

    if normalized == "/new":
        state[chat_key] = {"session_id": None, "pending": False}
        send_message(chat_id, "Started a new conversation.")
        return

    if tier == "readonly":
        resp = run_claude(text, chat_state["session_id"], readonly=True, chat_id=chat_id)
        chat_state["session_id"] = resp.get("session_id", chat_state["session_id"])
        chat_state["pending"] = False
        state[chat_key] = chat_state
        send_message(chat_id, resp.get("result", "(no response)"))
        return

    if chat_state["pending"] and normalized in AFFIRM:
        resp = run_claude("Yes, proceed with that action.", chat_state["session_id"], bypass=True, chat_id=chat_id)
    elif chat_state["pending"] and normalized in DENY:
        resp = run_claude("No, don't do that. Cancel the pending action.", chat_state["session_id"], bypass=False, chat_id=chat_id)
    else:
        resp = run_claude(text, chat_state["session_id"], bypass=False, chat_id=chat_id)

    chat_state["session_id"] = resp.get("session_id", chat_state["session_id"])
    denials = resp.get("permission_denials") or []
    chat_state["pending"] = bool(denials)
    state[chat_key] = chat_state

    reply = resp.get("result", "(no response)")
    if denials:
        reply += ("\n\n⚠️ Needs your confirmation to proceed:\n" + describe_denials(denials) +
                   "\n\nReply 'yes' to proceed or 'no' to cancel.")
    send_message(chat_id, reply)


def main():
    state = load_state()
    offset = state.get("_offset", 0)
    log("bot starting")
    while True:
        try:
            resp = api_call("getUpdates", {"offset": offset, "timeout": 30}, timeout=35)
        except Exception as e:
            log(f"getUpdates failed: {e}")
            time.sleep(5)
            continue

        for update in resp.get("result", []):
            offset = update["update_id"] + 1
            state["_offset"] = offset
            msg = update.get("message")
            if not msg or "text" not in msg:
                continue
            chat_id = msg["chat"]["id"]
            user_id = msg["from"]["id"]
            text = msg["text"]
            try:
                handle_message(chat_id, user_id, text, state)
            except Exception as e:
                log(f"handle_message error: {e!r}")
                send_message(chat_id, f"Internal error: {e}")
            save_state(state)


if __name__ == "__main__":
    main()
