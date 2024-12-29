#!/usr/bin/env bash

# A convenience script to run our ring-based P4 switch demo.

# Exit on error
set -e

# 1. Start the P4 environment using p4app
echo "[INFO] Starting P4 ring topology..."
p4app run ./p4app.json &

# Wait a couple of seconds for the environment to boot
sleep 3

# 2. Show the topology
echo "[INFO] Displaying network topology..."
p4app show

# 3. Test connectivity by pinging from each host to the others
echo "[INFO] Testing ping from h1 -> h2 -> h3..."
p4app exec m h1 ping 10.0.2.1 -c 2
p4app exec m h1 ping 10.0.3.1 -c 2

echo "[INFO] Testing ping from h2 -> h1 -> h3..."
p4app exec m h2 ping 10.0.1.1 -c 2
p4app exec m h2 ping 10.0.3.1 -c 2

echo "[INFO] Testing ping from h3 -> h1 -> h2..."
p4app exec m h3 ping 10.0.1.1 -c 2
p4app exec m h3 ping 10.0.2.1 -c 2

echo "[INFO] P4 ring demo complete. Press Ctrl+C to exit."
sleep infinity
