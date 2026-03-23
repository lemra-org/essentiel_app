#!/bin/bash
# Script to add namespace to Flutter plugins for AGP 8+ compatibility

PLUGINS=(
  "sensors_plus-1.4.1"
  "shared_preferences-2.2.2"
  "shared_preferences_android-2.2.1"
  "path_provider-2.1.1"
  "path_provider_android-2.2.1"
  "fluttertoast-8.2.5"
  "flutter_svg-2.0.5"
)

for PLUGIN in "${PLUGINS[@]}"; do
  PLUGIN_DIR="$HOME/.pub-cache/hosted/pub.dev/$PLUGIN"

  if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Plugin directory not found: $PLUGIN_DIR"
    continue
  fi

  BUILD_GRADLE="$PLUGIN_DIR/android/build.gradle"
  MANIFEST="$PLUGIN_DIR/android/src/main/AndroidManifest.xml"

  if [ ! -f "$BUILD_GRADLE" ]; then
    echo "build.gradle not found for $PLUGIN"
    continue
  fi

  # Extract package name from AndroidManifest.xml
  if [ -f "$MANIFEST" ]; then
    PACKAGE=$(grep -oP 'package="\K[^"]+' "$MANIFEST" 2>/dev/null)

    if [ -n "$PACKAGE" ]; then
      echo "Processing $PLUGIN (namespace: $PACKAGE)"

      # Add namespace to build.gradle if not present
      if ! grep -q "namespace" "$BUILD_GRADLE"; then
        sed -i "/apply plugin: 'com.android.library'/a\\\nandroid {\n    namespace \"$PACKAGE\"" "$BUILD_GRADLE" 2>/dev/null || \
        sed -i "/android {/a\    namespace \"$PACKAGE\"" "$BUILD_GRADLE"
      fi

      # Remove package attribute from AndroidManifest.xml
      sed -i 's/ *package="[^"]*"//' "$MANIFEST"
    fi
  fi
done

echo "Done fixing plugin namespaces"
