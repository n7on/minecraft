#!/usr/bin/env bash
# Builds one plugin under custom-plugins/<name>/ (a Maven project, see
# _template/) using a Maven+Java 25 container -- no local Java/Maven needed
# -- and drops the resulting jar into data/plugins/.
#
# Usage: ./build.sh <plugin-name>
set -euo pipefail
cd "$(dirname "$0")"

PLUGIN_NAME="${1:?Usage: ./build.sh <plugin-name> (a folder under custom-plugins/)}"
PLUGIN_DIR="$(pwd)/$PLUGIN_NAME"
PLUGINS_OUT="$(pwd)/../data/plugins"

if [ ! -f "$PLUGIN_DIR/pom.xml" ]; then
  echo "No pom.xml found at $PLUGIN_DIR -- copy _template/ to a new folder first." >&2
  exit 1
fi

echo "Building $PLUGIN_NAME..."
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -v "$PLUGIN_DIR":/app \
  -v maven-repo-cache:/tmp/.m2 \
  -w /app \
  maven:3.9-eclipse-temurin-25 \
  mvn -q -B package

JAR=$(find "$PLUGIN_DIR/target" -maxdepth 1 -name "*.jar" ! -name "original-*.jar" | head -1)
if [ -z "$JAR" ]; then
  echo "Build succeeded but no jar found in $PLUGIN_DIR/target" >&2
  exit 1
fi

cp "$JAR" "$PLUGINS_OUT/"
echo "Copied $(basename "$JAR") to data/plugins/."
echo "Restart to load it: docker compose stop minecraft && docker compose up -d"
