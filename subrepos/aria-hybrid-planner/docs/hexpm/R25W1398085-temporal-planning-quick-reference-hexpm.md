# R25W1398085: Temporal Planning Quick Reference (HexPM Documentation)

**Status:** Completed
**Date:** 2025-06-28
**Source:** Extracted from unified durative action specification for HexPM documentation

## Entity Model Summary

Everything is an entity with capabilities:

```elixir
# Entity types with capabilities
%{type: "agent", capabilities: [:cooking, :menu_planning]}
%{type: "oven", capabilities: [:heating, :baking]}
%{type: "kitchen", capabilities: [:workspace]}
%{type: "flour", capabilities: [:consumable]}
```

## Temporal Patterns (8 Valid Combinations)

| Pattern | start | end | duration | Semantics |
|---------|-------|-----|----------|-----------|
| 1 | ❌ | ❌ | ❌ | Instant action, anytime |
| 2 | ❌ | ❌ | ✅ | Floating duration |
| 3 | ❌ | ✅ | ❌ | Deadline constraint |
| 4 | ❌ | ✅ | ✅ | **Calculated start** (`start = end - duration`) |
| 5 | ✅ | ❌ | ❌ | Open start |
| 6 | ✅ | ❌ | ✅ | **Calculated end** (`end = start + duration`) |
| 7 | ✅ | ✅ | ❌ | Fixed interval |
| 8 | ✅ | ✅ | ✅ | **Constraint validation** (`start + duration = end`) |

## Method Types Overview

- **@action** - Direct state changes (cooking, moving, etc.)
- **@command** - Execution-time logic with failure handling
- **@task_method** - Break complex goals into smaller steps
- **@unigoal_method** - Handle single predicate goals like "location" or "status"
- **@multigoal_method** - Optimize solving multiple goals together
- **@multitodo_method** - Optimize processing lists of work items

## Primary API Functions

```elixir
# Planning only - returns plan result with solution tree
@spec plan(AriaHybridPlanner.domain(), AriaState.t(), [AriaHybridPlanner.todo_item()], keyword()) :: AriaHybridPlanner.plan_result()

# Planning + execution - returns solution tree and final state
@spec run_lazy(AriaHybridPlanner.domain(), AriaState.t(), [AriaHybridPlanner.todo_item()], keyword()) :: AriaHybridPlanner.execution_result()

# Take a pre-made plan and execute it.
@spec run_lazy_tree(AriaHybridPlanner.domain(), AriaState.t(), AriaHybridPlanner.solution_tree(), keyword()) :: AriaHybridPlanner.execution_result()
```

## Required Function Attributes

```elixir
@action true
@command true
@task_method true
@unigoal_method predicate: "is_predicate"
@multigoal_method true
@multitodo_method true
```

## Goal Format Standard

**ONLY use this format:**

```elixir
{predicate, subject, value}  # ✅ CORRECT
```

## State Validation

**ONLY use direct fact checking:**

```elixir
AriaState.RelationalState.get_fact(state, predicate, subject)  # ✅ CORRECT
