#!/bin/sh
set -e

# Load environment variables with defaults
VNC_DISPLAY=${VNC_DISPLAY:-:1}
VNC_PORT=${VNC_PORT:-5901}
VNC_GEOMETRY=${VNC_GEOMETRY:-1920x1080}
VNC_DEPTH=${VNC_DEPTH:-24}
NOVNC_PORT=${NOVNC_PORT:-8080}
MCP_PORT=${MCP_PORT:-9222}
VNC_PASSWORD=${VNC_PASSWORD:-browser-use}

# Set VNC password from environment variable
echo "Setting VNC password..."
echo "$VNC_PASSWORD" | vncpasswd -f > /home/playwright/.vnc/passwd
chmod 600 /home/playwright/.vnc/passwd

# Start VNC server with configurable settings
echo "Starting VNC server on display $VNC_DISPLAY (port $VNC_PORT)..."
vncserver $VNC_DISPLAY -geometry $VNC_GEOMETRY -depth $VNC_DEPTH -localhost no -xstartup /usr/bin/xterm

# Wait for VNC server to be ready
echo "Waiting for VNC server to be ready..."
sleep 5

# Start noVNC proxy with configurable port
echo "Starting noVNC proxy on port $NOVNC_PORT..."
websockify --web /usr/share/novnc/ $NOVNC_PORT localhost:$VNC_PORT &

# Set DISPLAY for Playwright (noVNC mode)
export DISPLAY=$VNC_DISPLAY

# Wait for noVNC to be ready
echo "Waiting for noVNC proxy to be ready..."
sleep 3

# Default arguments and port
MCP_ARGS=""
INTERNAL_PORT=${MCP_PORT:-9222}

# Add --port if MCP_PORT is set (for SSE connection)
if [ -n "$MCP_PORT" ]; then
  MCP_ARGS="$MCP_ARGS --port $INTERNAL_PORT"
fi

echo "Starting @playwright/mcp with args: $MCP_ARGS $@"
echo "Internal MCP port (if using SSE): $INTERNAL_PORT"
echo "VNC server running on port $VNC_PORT"
echo "noVNC web interface available at http://localhost:$NOVNC_PORT"

# Execute @playwright/mcp using npx
exec npx @playwright/mcp@0.0.7 $MCP_ARGS "$@"
