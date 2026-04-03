#!/usr/bin/env bash
# Ensures node_modules and bower_components exist when using named volumes
# (they mask image layers) or when the repo is cloned without bower_components.
set -e
cd /app

git config --global url."https://github.com/".insteadOf "git://github.com/" 2>/dev/null || true

need_npm=false
if [[ ! -x node_modules/.bin/grunt ]] && [[ ! -x node_modules/grunt-cli/bin/grunt ]]; then
	need_npm=true
fi
if [[ ! -d node_modules ]] || [[ -z "$(ls -A node_modules 2>/dev/null)" ]]; then
	need_npm=true
fi

if [[ "${need_npm}" == "true" ]]; then
	echo ">>> [entrypoint] Installing npm dependencies (node-gyp may compile native addons)..."
	npm install
fi

if [[ ! -d bower_components ]] || [[ -z "$(ls -A bower_components 2>/dev/null)" ]]; then
	echo ">>> [entrypoint] Installing bower dependencies..."
	node node_modules/bower/bin/bower install --allow-root
fi

exec "$@"
