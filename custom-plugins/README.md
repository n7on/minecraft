# Custom plugins

Real Paper plugins (compiled Java, not datapack JSON) for things that need
actual code: custom commands, GUIs, event handling, persistent data, etc.
No local Java/Maven needed -- `build.sh` compiles via a Maven+Java 25
container and drops the result straight into `data/plugins/`.

## Creating a new one

1. Copy the template to a new folder named after the plugin:
   ```sh
   cp -r _template my-plugin-name
   ```
2. In `my-plugin-name/pom.xml`: change `groupId`, `artifactId`, `name`.
3. In `my-plugin-name/src/main/resources/plugin.yml`: change `name` and
   `main` (the main class's full package path) to match.
4. Rename the Java file/package/class under `src/main/java/` to whatever
   fits (the folder structure must match the package declaration), and
   write the actual plugin logic there.
5. Build and deploy:
   ```sh
   ./build.sh my-plugin-name
   ```
6. Restart to load it:
   ```sh
   docker compose stop minecraft && docker compose up -d
   ```

## Notes

- The Paper API version in `_template/pom.xml` (`26.2.build.135-stable`)
  must match the server's actual running build -- check `data/.paper.env`
  if the server version ever changes and plugins stop compiling against
  the right API.
- Each plugin's `target/` build output is gitignored; only the source goes
  in git.
- [Paper's plugin API docs](https://docs.papermc.io/paper/dev/getting-started/paper-plugins)
  are the reference for what's possible (commands, listeners, scheduling,
  persistent data, etc.).
