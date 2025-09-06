# **R25W1900002 - README Content Migration to Decision Records**

**Status:** Approved

**Date:** September 6, 2025

**Context:** The README.md file has grown too complex with detailed sections that are better suited as architectural decision records. This migration moves all detailed content into the decisions/ directory while keeping the README as a simple one-page overview.

## **Decision**

We will migrate all detailed sections from README.md into this ADR document and simplify the README to a concise one-page summary.

## **Migrated Content**

### Overview

This project implements a LitRPG Guild Master game where players make strategic decisions while autonomous AI heroes execute complex multi-step quests. The game demonstrates autonomous AI agents with persistent world simulation and real-time Godot visualization.

### Architecture

- **Backend**: Elixir with HTN (Hierarchical Task Network) planning
- **Persistence**: PostgreSQL with ordinary relational schema
- **Client**: Godot 3D engine with Membrane Unifex integration
- **Planning**: Aria Hybrid Planner for autonomous hero execution

### Key Features

- Autonomous AI heroes executing complex quest plans
- Strategic quest acceptance and hero assignment
- Persistent world state with complete history
- Real-time 3D visualization in Godot
- Simple PostgreSQL persistence

### Quick Start

#### Prerequisites

- Elixir 1.17+
- PostgreSQL (for persistence)
- Git (for subrepo management)

#### Installation

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
   # FIXME: Create database
   createdb guildmasters_ledger_dev

   # FIXME: Run the elixir migrations
   ```

4. **Start the application:**
   ```bash
   mix run --no-halt
   ```

#### Basic Usage

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

### Core Concepts

#### HTN Planning

The game uses Hierarchical Task Network (HTN) planning to enable autonomous hero behavior:

- **Actions**: Direct state transformations (move, fight, loot)
- **Methods**: Break complex goals into simpler tasks
- **Goals**: Desired world states (quest completed, hero available)

#### Entity System

All game objects are entities with types and capabilities:

```elixir
# Hero entity
%{type: "hero", capabilities: [:adventuring, :fighting]}

# Location entity
%{type: "location", capabilities: [:dangerous, :resource_rich]}
```

#### Simple Persistence

World state is persisted using a simple relational schema:

- **Facts Table**: Stores game facts as (predicate, subject, value) triples
- **Direct API Support**: Compatible with HTN planning `get_fact`/`set_fact` operations
- **Performance**: Optimized for simple fact queries and updates

### Development

#### Running Tests

```bash
mix test
```

#### Code Quality

```bash
# Run dialyzer for type checking
mix dialyzer

# Format code
mix format

# Run credo for code quality
mix credo
```

#### Planning Engine Integration

The project uses `aria-hybrid-planner` as a git subrepo:

```bash
# Update the subrepo
git subrepo pull subrepos/aria-hybrid-planner

# Push changes back to subrepo
git subrepo push subrepos/aria-hybrid-planner
```

### API Reference

#### Domain Functions

- `GuildmastersLedger.Domain.GuildMaster.create_domain/0` - Create HTN domain
- `GuildmastersLedger.Domain.GuildMaster.setup_guild_scenario/2` - Initialize game world
- `GuildmastersLedger.Domain.GuildMaster.complete_quest_workflow/2` - Plan quest execution

#### Planning Functions

- `AriaHybridPlanner.plan/4` - Generate execution plan
- `AriaHybridPlanner.run_lazy/4` - Plan and execute
- `AriaHybridPlanner.run_lazy_tree/4` - Execute pre-made plan

### Roadmap

#### Phase 1: Core Planning (Current)
- ✅ HTN domain implementation
- ✅ Basic hero actions (move, fight, quest)
- ✅ Quest workflow planning
- 🔄 PostgreSQL persistence integration

#### Phase 2: Autonomous Heroes
- ⏳ Hero GenServer for autonomous execution
- ⏳ Goal processing and replanning
- ⏳ Multi-hero coordination

#### Phase 3: Godot Integration
- ⏳ Membrane Unifex NIFs for Godot embedding
- ⏳ Real-time hero movement visualization
- ⏳ Quest board UI

#### Phase 4: Persistence & Networking
- ⏳ Simple world state persistence
- ⏳ ENet real-time updates
- ⏳ Guild progression tracking

### Contributing

1. Follow the existing code style
2. Add tests for new functionality
3. Update documentation as needed
4. Ensure dialyzer passes

## **Consequences**

### **Positive**
- README remains clean and focused on essential information
- Detailed documentation is properly organized in decisions/
- Easier maintenance of both README and detailed docs
- Better separation of concerns between overview and implementation details

### **Related Decisions**
- [R25W1900001](apps/guildmasters_ledger/decisions/R25W1900001-v-sekai-september-jam-guildmasters-ledger.md) - Main game concept
- [R25W1398085](apps/guildmasters_ledger/decisions/R25W1398085-unified-durative-action-specification-and-planner-standardization.md) - HTN specification
- [R25W118994A](apps/guildmasters_ledger/decisions/R25W118994A-godot-libgodot-integration-via-membrane-unifex.md) - Godot integration
- [R25W1900003](R25W1900003-switch-to-ordinary-postgresql-schema.md) - Switch to ordinary PostgreSQL schema
