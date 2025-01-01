# P4 Ring Topology Demo

This repository demonstrates a **ring-based topology** using the P4 language and the bmv2 reference switch (via the `p4app` environment). 

## Features

- **Custom Data Plane**: We use a match-action table to forward packets in a ring.
- **CLI-based Table Population**: Each switch has its own commands file (`commands_s1.txt`, etc.) to specify forwarding rules.
- **Mininet-like Setup**: `p4app.json` describes the network of 3 hosts and 3 P4 switches.

## Requirements

- [p4lang/p4app](https://github.com/p4lang/p4app)  
  (Install via `pip install p4app` or from source)
- Python 3
