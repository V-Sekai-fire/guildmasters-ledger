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

## Quick Start

### Prerequisites

- Elixir 1.17+
- PostgreSQL (for persistence)
- Git (for subrepo management)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd guildmasters-ledger
   ```

2. **Install dependencies:**
   ```bash
   mix deps.get
   ```

3. **Setup PostgreSQL database:**
   ```bash
   # Create database
   createdb guildmasters_ledger_dev

   # Run the bitemporal schema
   psql -d guildmasters_ledger_dev -f decisions/bitemporal_6nf_postgres.sql
   ```

4. **Start the application:**
   ```bash
   mix run --no-halt
   ```

### Basic Usage

```elixir
# Start an interactive Elixir session
iex -S mix

# Create the domain
domain = GuildmastersLedger.Domain.GuildMaster.create_domain()

# Setup initial game state
{:ok, initial_state} = GuildmastersLedger.Domain.GuildMaster.setup_guild_scenario(AriaState.new(), [])

# Plan a quest execution
{:ok, solution_tree} = AriaHybridPlanner.plan(domain, initial_state, [
  {:complete_quest_workflow, ["quest_1", "hero_1"]}
])

# Execute the plan
{:ok, {final_state, _tree}} = AriaHybridPlanner.run_lazy_tree(domain, initial_state, solution_tree)
```

## Project Structure

```
guildmasters-ledger/
├── decisions/                    # Architectural decision records
│   ├── R25W1900001-v-sekai-september-jam-guildmasters-ledger.md
│   ├── R25W1398085-unified-durative-action-specification-and-planner-standardization.md
│   ├── R25W118994A-godot-libgodot-integration-via-membrane-unifex.md
│   └── bitemporal_6nf_postgres.sql
├── lib/
│   └── guildmasters_ledger/
│       ├── application.ex        # Application supervisor
│       ├── domain/
│       │   └── guild_master.ex   # HTN planning domain
│       └── guildmasters_ledger.ex # Main module
├── subrepos/
│   └── aria-hybrid-planner/      # Git subrepo for planning engine
├── config/                       # Configuration files
├── test/                         # Test files
├── priv/                         # Private assets
├── mix.exs                       # Project configuration
└── README.md
```

## Core Concepts

### HTN Planning

The game uses Hierarchical Task Network (HTN) planning to enable autonomous hero behavior:

- **Actions**: Direct state transformations (move, fight, loot)
- **Methods**: Break complex goals into simpler tasks
- **Goals**: Desired world states (quest completed, hero available)

### Entity System

All game objects are entities with types and capabilities:

```elixir
# Hero entity
%{type: "hero", capabilities: [:adventuring, :fighting]}

# Location entity
%{type: "location", capabilities: [:dangerous, :resource_rich]}
```

### Bitemporal Persistence

World state is persisted using bitemporal 6NF:

- **Valid Time**: When facts are true in the game world
- **Transaction Time**: When facts were recorded in the database
- **Immutability**: Changes create new records, never modify existing ones

## Development

### Running Tests

```bash
mix test
```

### Code Quality

```bash
# Run dialyzer for type checking
mix dialyzer

# Format code
mix format

# Run credo for code quality
mix credo
```

### Planning Engine Integration

The project uses `aria-hybrid-planner` as a git subrepo:

```bash
# Update the subrepo
git subrepo pull subrepos/aria-hybrid-planner

# Push changes back to subrepo
git subrepo push subrepos/aria-hybrid-planner
```

## API Reference

### Domain Functions

- `GuildmastersLedger.Domain.GuildMaster.create_domain/0` - Create HTN domain
- `GuildmastersLedger.Domain.GuildMaster.setup_guild_scenario/2` - Initialize game world
- `GuildmastersLedger.Domain.GuildMaster.complete_quest_workflow/2` - Plan quest execution

### Planning Functions

- `AriaHybridPlanner.plan/4` - Generate execution plan
- `AriaHybridPlanner.run_lazy/4` - Plan and execute
- `AriaHybridPlanner.run_lazy_tree/4` - Execute pre-made plan

## Roadmap

### Phase 1: Core Planning (Current)
- ✅ HTN domain implementation
- ✅ Basic hero actions (move, fight, quest)
- ✅ Quest workflow planning
- 🔄 PostgreSQL persistence integration

### Phase 2: Autonomous Heroes
- ⏳ Hero GenServer for autonomous execution
- ⏳ Goal processing and replanning
- ⏳ Multi-hero coordination

### Phase 3: Godot Integration
- ⏳ Membrane Unifex NIFs for Godot embedding
- ⏳ Real-time hero movement visualization
- ⏳ Quest board UI

### Phase 4: Persistence & Networking
- ⏳ Bitemporal world state persistence
- ⏳ ENet real-time updates
- ⏳ Guild progression tracking

## Contributing

1. Follow the existing code style
2. Add tests for new functionality
3. Update documentation as needed
4. Ensure dialyzer passes

## License

This project is part of the V-Sekai September Jam and follows the same licensing as the parent project.

## Related Decisions

- [R25W1900001](decisions/R25W1900001-v-sekai-september-jam-guildmasters-ledger.md) - Main game concept
- [R25W1398085](decisions/R25W1398085-unified-durative-action-specification-and-planner-standardization.md) - HTN specification
- [R25W118994A](decisions/R25W118994A-godot-libgodot-integration-via-membrane-unifex.md) - Godot integration
- [bitemporal_6nf_postgres.sql](decisions/bitemporal_6nf_postgres.sql) - Persistence schema
