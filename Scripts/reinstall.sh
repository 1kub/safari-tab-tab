#!/bin/bash
# Backward-compatible alias for install.sh
exec "$(cd "$(dirname "$0")" && pwd)/install.sh" "$@"
