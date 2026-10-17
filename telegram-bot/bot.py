#!/usr/bin/env python3
"""Telegram <-> Claude Code bridge for admin'ing the Minecraft server.

Each authorized Telegram message is forwarded as a prompt to `claude -p`,
run with cwd set to the project directory, using bot-settings.json's
allow/deny list. Anything not explicitly allowed is auto-denied (no human
to prompt); a denial is surfaced back to the chat as a yes/no confirmation
ask, and a "yes" reply resumes the same Claude session with
--permission-mode bypassPermissions for that one turn to complete it.
"""
import json
import os
import subprocess
import time
import urllib.request
from pathlib import Path

BOT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = os.environ.get("PROJECT_DIR", str(BOT_DIR.parent))
CLAUDE_BIN = os.environ.get("CLAUDE_BIN", "/home/anton/.local/bin/claude")
BOT_TOKEN = os.environ["BOT_TOKEN"]
ALLOWED_USER_IDS = {int(x) for x in os.environ.get("ALLOWED_USER_IDS", "").split(",") if x.strip()}
SETTINGS_FILE = str(BOT_DIR / "bot-settings.json")
STATE_FILE = BOT_DIR / "state.json"
LOG_FILE = BOT_DIR / "bot.log"
API_BASE = f"https://api.telegram.org/bot{BOT_TOKEN}"

AFFIRM = {"yes", "y", "confirm", "go ahead", "do it", "proceed"}
DENY = {"no", "n", "cancel", "stop", "don't", "dont"}

SYSTEM_PROMPT = (
    "You are controlling a docker-compose Minecraft server (itzg/minecraft-server) "
    "for the admin's son and his friends, via Telegram messages from the admin. "
    "The project directory (docker-compose.yml, README.md) is your working directory. "
    "The world data, server jar, plugins, cache and logs live under data/ and are "
    "gitignored runtime state. If a command you tried is blocked by permissions, "
    "clearly tell the admin what you wanted to run and why, so they can decide. "
    "Keep replies short and plain text (this is a Telegram chat, sent with no markdown "
    "parsing): no asterisks, headers, or backticks for formatting. If you edit docker-compose.yml, briefly "
    "say what changed and that 'docker compose up -d' is needed to apply it (you can "
    "run that yourself)."
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
        return json.loads(resp.read())


def send_message(chat_id, text):
    text = text or "(no response)"
    for i in range(0, len(text), 4000):
        chunk = text[i:i + 4000]
        try:
            api_call("sendMessage", {"chat_id": chat_id, "text": chunk})
        except Exception as e:
            log(f"sendMessage failed: {e}")


def run_claude(prompt, session_id=None, bypass=False):
    cmd = [CLAUDE_BIN, "-p", prompt, "--output-format", "json",
           "--settings", SETTINGS_FILE, "--append-system-prompt", SYSTEM_PROMPT]
    if bypass:
        cmd += ["--permission-mode", "bypassPermissions"]
    else:
        cmd += ["--permission-mode", "dontAsk", "--permission-prompts", "none"]
    if session_id:
        cmd += ["--resume", session_id]

    log(f"-> session={session_id} bypass={bypass} prompt={prompt!r}")
    try:
        result = subprocess.run(cmd, cwd=PROJECT_DIR, capture_output=True, text=True, timeout=900)
    except subprocess.TimeoutExpired:
        log("claude invocation timed out")
        return {"result": "Timed out waiting for Claude.", "session_id": session_id, "permission_denials": []}

    if result.returncode != 0:
        log(f"claude exited {result.returncode}: {result.stderr[-2000:]}")
        return {"result": f"Internal error (exit {result.returncode}). Check bot.log.",
                "session_id": session_id, "permission_denials": []}
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        log(f"bad json from claude: {result.stdout[-2000:]}")
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
    if user_id not in ALLOWED_USER_IDS:
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

    if chat_state["pending"] and normalized in AFFIRM:
        resp = run_claude("Yes, proceed with that action.", chat_state["session_id"], bypass=True)
    elif chat_state["pending"] and normalized in DENY:
        resp = run_claude("No, don't do that. Cancel the pending action.", chat_state["session_id"], bypass=False)
    else:
        resp = run_claude(text, chat_state["session_id"], bypass=False)

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
