#!/bin/bash

# Hugo development server startup script
# Optimized for content refresh and cache settings

echo "Starting Hugo development server..."

# Clean cache
echo "Cleaning Hugo cache..."
rm -rf resources/_gen
rm -rf .hugo_build.lock

# Start server with fast render disabled and HTTP cache disabled
hugo server \
  --disableFastRender \
  --noHTTPCache \
  --ignoreCache \
  --disableBrowserError \
  --navigateToChanged \
  --buildDrafts \
  --buildFuture \
  --gc \
  --environment production \
  --port 1313 \
  --bind 0.0.0.0

