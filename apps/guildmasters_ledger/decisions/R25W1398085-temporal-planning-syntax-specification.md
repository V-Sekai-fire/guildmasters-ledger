# **R25W1398085 - Temporal Planning Syntax Specification**

**Status:** Proposed | **Date:** September 6, 2025

## **Context**
Need exact syntax specification for temporal planning in Guildmaster's Ledger. Define concrete syntax for durative actions, entity capabilities, and HTN planning constructs.

## **Decision**
Standardize syntax: `@action duration: "PT2H", start: "2025-09-06T10:00:00-07:00"` for durative actions, `{:goal, {"location", "hero_1", "dungeon"}}` for goals, entity traits as atoms.

## **Success Criteria**
Syntax examples provided, durative action patterns defined, entity capability syntax specified, HTN constructs documented, validation rules established.

## **Timeline**
Complete syntax specification by September 10, validate with implementation by September 12.

## **Next Steps**
1. `@action duration: "PT2H", requires_entities: [%{type: "hero", capabilities: [:fighting]}]`
2. `{:goal, {"quest_status", "quest_1", "completed"}}`
3. `{:task, ["travel_to_dungeon", "fight_goblins", "collect_loot"]}`
4. Entity: `%{type: "hero", capabilities: [:adventuring, :magic], id: "hero_1"}`
5. Method: `@unigoal_method predicate: "location"`
