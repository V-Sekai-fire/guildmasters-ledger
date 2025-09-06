# R25W1398085: Reference & Standards (HexPM Documentation)

**Status:** Completed
**Date:** 2025-06-28
**Source:** Extracted from unified durative action specification for HexPM documentation

## Success Criteria

**Planning Paradigm Alignment:**
- ✅ Clear distinction between programming vs planning documented
- ✅ All examples show planner-controlled execution
- ✅ Action functions designed as pure state transformations
- ✅ Domain registration supports planner discovery

**Technical Implementation:**
- ✅ Floating durations and fixed intervals supported via ISO 8601
- ✅ Unified action specification with entities and capabilities
- ✅ All goals use `{predicate, subject, value}` format
- ✅ State validation uses direct `State.get_fact/3` calls
- ✅ Standardized `@action` attribute definitions

## Tombstoned Concepts

The following concepts were explicitly rejected:

1. **❌ `quantity` field in action metadata** - Quantities are state fluents
2. **❌ Separate `resources` map** - Everything is entities with capabilities
3. **❌ `properties` field in entity requirements** - Use capabilities instead
4. **❌ Separate `requires_agent` field** - Agents are entities with capabilities
5. **❌ `location` field in action metadata** - Locations are entities
6. **❌ Requirement validation in action functions** - Planner validates requirements
7. **❌ Mixed goal formats** - ONLY `{predicate, subject, value}` allowed
8. **❌ Complex state evaluation functions** - Use direct fact checking
9. **❌ Temporal conditions in durative actions** - Use method decomposition
10. **❌ Functions without attributes** - All planner functions need attributes

## Academic Foundation

This specification builds upon established research in automated planning:

**Temporal Planning:**
- Fox, M.; Long, D. (2003). "PDDL2.1: An Extension to PDDL for Expressing Temporal Planning Domains". *Journal of Artificial Intelligence Research*, 20:61-124.

**Automated Planning Theory:**
- Ghallab, M.; Nau, D.; Traverso, P. (2004). *Automated Planning: Theory and Practice*. Morgan Kaufmann.

**Constraint Programming:**
- Nethercote, N.; Stuckey, P.J.; et al. (2007). "MiniZinc: Towards a Standard CP Modelling Language". *CP 2007*.

**Temporal Reasoning:**
- Dechter, R.; Meiri, I.; Pearl, J. (1991). "Temporal constraint networks". *Artificial Intelligence*, 49(1-3):61-95.

## Standards

- **ISO 8601-1:2019** Date and time representations
- **Khronos Group glTF 2.0** and KHR_interactivity specifications

## Implementation Status

**Status:** Completed - Core specification fully implemented and integrated.
**Usage:** Foundation for all AriaEngine domain development. All new domain definitions should use `AriaEngine.Domain`.
**Timeline:** Available immediately.
**Compatibility:** Full backward compatibility maintained.

## Overview

**Current State:** Multiple confusing and inconsistent patterns across AriaEngine planner

**Target State:** Single unified specification for durative actions with entities, capabilities, and temporal constraints

This specification provides a complete framework for temporal planning with durative actions, entity-based resource management, and hierarchical task decomposition. It addresses the complexity of multi-agent coordination while maintaining simplicity for single-agent scenarios.

## Contributors

- K. S. Ernest Lee, V-Sekai (<https://v-sekai.org>) and Chibifire.com (<https://chibifire.com>), <ernest.lee@chibifire.com>
