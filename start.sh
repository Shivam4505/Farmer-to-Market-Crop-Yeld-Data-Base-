#!/bin/bash
# ==============================================================================
# Farmer Market Advisor — Quick Start Script
# Runs the complete application (Frontend + Backend) on http://localhost:5001
# ==============================================================================

# 1. Ensure Node.js and Postgres are in PATH
export PATH="/Users/shiv/.node/bin:/Applications/Postgres.app/Contents/Versions/latest/bin:/opt/homebrew/bin:$PATH"

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

# 2. Check if PostgreSQL is accepting connections on port 5432
if ! nc -z localhost 5432 2>/dev/null; then
  echo ">>> PostgreSQL is not running on port 5432."
  if [ -d "/Applications/Postgres.app" ]; then
    echo ">>> Launching Postgres.app..."
    open -a Postgres
    for i in {1..10}; do
      sleep 1
      if nc -z localhost 5432 2>/dev/null; then
        echo ">>> PostgreSQL is now running!"
        break
      fi
    done
  fi
fi

# 3. Check if port 5001 is already occupied by a previous instance
OLD_PID=$(lsof -ti :5001 2>/dev/null)
if [ -n "$OLD_PID" ]; then
  echo ">>> Port 5001 is currently occupied by PID: $OLD_PID. Stopping old instance..."
  kill -9 $OLD_PID 2>/dev/null || true
  sleep 1
fi

# 4. Check if frontend dist exists; build if missing
if [ ! -d "$PROJECT_ROOT/frontend/dist" ] || [ ! -f "$PROJECT_ROOT/frontend/dist/index.html" ]; then
  echo ">>> Building frontend assets for production..."
  (cd "$PROJECT_ROOT/frontend" && npm run build)
fi

echo "========================================================================"
echo " Starting Farmer Market Advisor Dashboard..."
echo " Live Application URL: http://localhost:5001"
echo "========================================================================"

cd "$PROJECT_ROOT/backend" && node server.js
