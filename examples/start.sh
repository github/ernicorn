#!/bin/sh
# Start the example ernicorn server on port 9777.
cd "$(dirname "$0")"
exec ernicorn config.rb
