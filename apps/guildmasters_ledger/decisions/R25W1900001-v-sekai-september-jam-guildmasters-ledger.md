# **R25W1900001 - V-Sekai September Jam: Guildmaster's Ledger**

**Status:** Proposed | **Date:** September 6, 2025

## **Context**
V-Sekai September Jam pivots to Guild Master role, maintaining autonomous AI agents and persistent world simulation. Demonstrates autonomous AI heroes in LitRPG setting where players make strategic decisions as guild leaders.

## **Decision**
Implement LitRPG Guild Master game showcasing autonomous AI agents with meaningful player agency through strategic quest management. Technical stack: Elixir backend with HTN planning, PostgreSQL persistence, Godot visualization.

## **Success Criteria**
Autonomous hero executes complete multi-step quest, quest results permanently saved to PostgreSQL, Guild Master accepts quests and assigns heroes, real-time hero movement visualization in Godot, end-to-end gameplay loop.

## **Timeline**
Complete game by October 4, 2025. Week 1: AI Backend, Week 2: Persistence, Week 3: Godot Client, Week 4: Polish & Demo.

## **Next Steps**
1. Implement Hero GenServer with goal processing
2. Integrate HTN planner for multi-step quest execution
3. Create Quest Board GenServer for quest generation
4. Implement SnapshotManager for PostgreSQL persistence
5. Build Godot 3D client with Guild Hall and quest visualization
