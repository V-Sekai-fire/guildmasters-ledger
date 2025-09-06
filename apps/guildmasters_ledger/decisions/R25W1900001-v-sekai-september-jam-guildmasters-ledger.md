# **R25W1900001 \- V-Sekai September Jam: The Guildmaster's Ledger**

**Status:** Proposed

**Date:** September 6, 2025

**Source:** Copied from aria-character-core/decisions/R25W1900001-v-sekai-september-jam-guildmasters-ledger.md

**Context:** This is the main decision document for the Guildmaster's Ledger game jam project. It defines the core concept of a LitRPG Guild Master game with autonomous AI heroes.

## **Context & Background**

The V-Sekai September Jam pivots from the Dungeon Core concept to the Guild Master role, maintaining the core technical objectives of autonomous AI agents and persistent world simulation while providing a more compelling gameplay experience. This game jam will demonstrate the power of autonomous AI heroes in a LitRPG setting where players make strategic decisions as guild leaders.

The theme "Genesis & Echo" is interpreted through the Guild Master's perspective: **Genesis** represents the player's strategic command when accepting quests and assigning heroes, while **Echo** represents the permanent marks left on the world's history through completed quests and changed world states.

## **Primary Objective**

By October 4, 2025, deliver a complete LitRPG game where players act as Guild Masters managing autonomous AI heroes. The game must demonstrate:

- Strategic quest acceptance and hero assignment
- Autonomous AI hero execution of complex multi-step plans
- Permanent world state changes saved to PostgreSQL
- Real-time visualization in a Godot 3D client
- Complete end-to-end gameplay loop

## **Key Deliverables & Success Criteria**

### **Milestone \#1: The Autonomous Adventurer (AI Backend)**

- **Description:** Create AI heroes capable of accepting quests and executing entire multi-step plans autonomously
- **Success Criteria:**
  - Hero `GenServer` receives high-level goal from player
  - HTN planner generates complete plan (e.g., `[TravelTo(Cave), Slay(Goblins), Loot(Treasure), ReturnTo(Guild)]`)
  - Hero executes plan via in-memory messages to world entities
  - Quest completion triggers guild rewards and world state changes

### **Milestone \#2: The World's History (Persistence Layer)**

- **Description:** Ensure quest results are permanent and world state changes persist
- **Success Criteria:**
  - `SnapshotManager` writes world state to PostgreSQL database
  - Cleared locations maintain `{is_cleared, true}` status across sessions
  - Guild gold and reputation changes are permanently saved
  - Quest history becomes part of persistent world narrative

### **Milestone \#3: The Guild Hall (Client)**

- **Description:** Provide strategic command interface for the Guild Master
- **Success Criteria:**
  - Godot 3D client with top-down view of Guild Hall and world map
  - Quest Board UI showing available quests
  - Hero movement visualization across the map
  - Real-time updates of quest progress and completion

### **The Final Demo (Gameplay Test)**

Player launches client, accepts "Clear Goblin Cave" quest from Quest Board. Hero capsule exits Guild Hall, travels to cave, returns with loot. Quest completion notification appears with gold reward. Cave remains cleared in subsequent sessions.

## **Rules of Engagement (Scope Boundaries)**

- **Strategic Focus:** Player makes high-level decisions, AI handles execution details
- **Autonomous AI:** Heroes execute complete plans without player micromanagement
- **Persistent World:** All changes saved to PostgreSQL database
- **Real-time Visualization:** Godot client shows hero movement and world updates
- **LitRPG Elements:** Guild gold, reputation, quest rewards

## **Resources & Timeline**

- **Team:** 1 Jammer
- **Duration:** 1 Month (September 6 \- October 4, 2025\)
- **Total Capacity:** 4 Weeks
- **Estimated Effort:** 3-4 weeks of focused development
- **Kick-off:** Saturday, September 6, 2025
- **Location:** YVR

## **Implementation Plan**

### **Week 1: The Autonomous Adventurer (Backend Core)**

- [ ] Implement Hero `GenServer` with goal processing
- [ ] Integrate HTN planner for multi-step quest execution
- [ ] Create Quest Board `GenServer` for quest generation
- [ ] Build in-memory world entity communication system
- [ ] Test autonomous hero quest completion

### **Week 2: The World's History (Persistence & Networking)**

- [ ] Implement `SnapshotManager` for PostgreSQL persistence
- [ ] Add world state serialization and deserialization
- [ ] Set up ENet broadcasting for real-time updates
- [ ] Create guild progression tracking (gold, reputation)
- [ ] Test persistent world state across sessions

### **Week 3: The Guild Hall (Godot Client & Integration)**

- [ ] Build Godot 3D client with top-down Guild Hall view
- [ ] Implement Quest Board UI with quest acceptance
- [ ] Add world map with hero movement visualization
- [ ] Connect ENet client to Elixir backend
- [ ] Integrate real-time quest progress updates

### **Week 4: Polish & Demo Preparation**

- [ ] Bug fixes and gameplay balancing
- [ ] Add quest completion notifications and rewards
- [ ] Polish UI and visual feedback
- [ ] Prepare final demo presentation
- [ ] Document setup and gameplay instructions

## **Decision**

We will implement this as a LitRPG Guild Master game that showcases autonomous AI agents while providing meaningful player agency through strategic quest management. The technical stack remains focused on Elixir backend with HTN planning, PostgreSQL persistence, and Godot visualization, but the gameplay is centered on high-level decision making rather than direct control.

## **Consequences/Risks**

### **Positive Consequences**

- Demonstrates autonomous AI in a compelling gameplay context
- Provides clear player agency through strategic decisions
- Showcases persistent world simulation with meaningful consequences
- Creates replayable gameplay through quest variety and progression
- Maintains technical focus on AI planning and world persistence

### **Negative Consequences**

- Complex AI planning may require significant debugging time
- Balancing autonomous execution with player engagement
- Quest generation variety may be limited in jam timeframe
- UI complexity for strategic interface

### **Risks**

- **High Risk:** HTN planner complexity and debugging
- **Medium Risk:** Balancing autonomous AI with player engagement
- **Low Risk:** Godot client integration (proven technology)

## **Success Criteria**

### **Must-Have (Critical Path)**

- [ ] Autonomous hero executes complete multi-step quest
- [ ] Quest results permanently saved to PostgreSQL
- [ ] Guild Master can accept quests and assign heroes
- [ ] Real-time hero movement visualization in Godot
- [ ] End-to-end gameplay: Quest → Execution → Reward → Persistence

### **Should-Have (Important but not critical)**

- [ ] Multiple quest types with different objectives
- [ ] Guild progression (gold, reputation, hero roster)
- [ ] Visual feedback for quest progress and completion
- [ ] Clean separation between strategic and tactical gameplay

### **Nice-to-Have (If time permits)**

- [ ] Multiple heroes with different specializations
- [ ] Quest chains and narrative progression
- [ ] Guild hall upgrades and customization
- [ ] Sound effects and music

## **Related ADRs**

- **R25W1398085:** Unified Durative Action Specification and Planner Standardization (for HTN integration)
- **R25W1900003:** Switch from Bitemporal 6NF to Ordinary PostgreSQL Schema (for world state persistence)
- **R25W118994A:** Godot LibGodot Integration via Membrane Unifex (for client visualization)

## **Notes**

This game jam serves as the perfect showcase for V-Sekai's autonomous AI and persistent world technology. By positioning the player as a Guild Master making strategic decisions, we maintain player agency while letting the AI shine in executing complex plans. The "Genesis & Echo" theme beautifully captures the player's role in initiating adventures and the lasting impact on the world.

The Guild Master concept provides a much more compelling gameplay experience than the Dungeon Core approach, while still achieving all the technical demonstration objectives of autonomous agents, persistent worlds, and real-time visualization.
