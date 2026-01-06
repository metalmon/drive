#!/bin/bash

if ! command -v pnpm &> /dev/null
then
    echo "pnpm could not be found, installing..."
    # Use npm with explicit registry mirror for Russia/China
    npm install -g pnpm@latest-10 --registry=https://registry.npmmirror.com
else
    echo "pnpm is already installed."
fi

echo "pnpm version: $(pnpm --version)"

exit 0