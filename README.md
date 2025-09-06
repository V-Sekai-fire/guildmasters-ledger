# Guildmaster's Ledger

A LitRPG Guild Master game for the V-Sekai September Jam where players make strategic decisions while autonomous AI heroes execute complex multi-step quests.

## Quick Start

```bash
git clone <repository-url>
cd guildmasters-ledger
mix deps.get
mix run --no-halt
```

## Architecture

- **Backend**: Elixir with HTN planning
- **Persistence**: PostgreSQL with bitemporal 6NF
- **Client**: Godot 3D with Membrane Unifex
- **Planning**: Aria Hybrid Planner

## Key Features

- Autonomous AI heroes executing complex quest plans
- Strategic quest acceptance and hero assignment
- Persistent world state with complete history
- Real-time 3D visualization in Godot

## Documentation

See [decisions/R25W1900002-readme-content-migration.md](decisions/R25W1900002-readme-content-migration.md) for detailed documentation, API reference, and development setup.
