# Guildmaster's Ledger

An independent Elixir app for the V-Sekai September Jam: The Guildmaster's Ledger

## Overview

This project implements a LitRPG Guild Master game where players make strategic decisions while autonomous AI heroes execute complex multi-step quests. The game demonstrates autonomous AI agents with persistent world simulation and real-time Godot visualization.

## Architecture

- **Backend**: Elixir with HTN (Hierarchical Task Network) planning
- **Persistence**: PostgreSQL with bitemporal 6NF schema
- **Client**: Godot 3D engine with Membrane Unifex integration
- **Planning**: Aria Hybrid Planner for autonomous hero execution

## Key Features

- Autonomous AI heroes executing complex quest plans
- Strategic quest acceptance and hero assignment
- Persistent world state with complete history
- Real-time 3D visualization in Godot
- Bitemporal PostgreSQL persistence

## Related Decisions

- [R25W1900001](decisions/R25W1900001-v-sekai-september-jam-guildmasters-ledger.md) - Main game concept
- [R25W1398085](decisions/R25W1398085-unified-durative-action-specification-and-planner-standardization.md) - HTN specification
- [R25W118994A](decisions/R25W118994A-godot-libgodot-integration-via-membrane-unifex.md) - Godot integration
- [bitemporal_6nf_postgres.sql](decisions/bitemporal_6nf_postgres.sql) - Persistence schema
