# R25W1398085: Core Specification (HexPM Documentation)

**Status:** Completed
**Date:** 2025-06-28
**Source:** Extracted from unified durative action specification for HexPM documentation

## Entity Registration Pattern

Before planning, entities must be registered with types and capabilities:

```elixir
@action true
@spec register_entity(AriaState.t(), [String.t(), String.t(), [capability()]]) :: {:ok, AriaState.t()} | {:error, atom()}
def register_entity(state, [entity_id, type, capabilities]) do
  state
  |> AriaState.RelationalState.set_fact("type", entity_id, type)
  |> AriaState.RelationalState.set_fact("capabilities", entity_id, capabilities)
  |> AriaState.RelationalState.set_fact("status", entity_id, "available")
  {:ok, state}
end
```

## Domain Definition Syntax

```elixir
defmodule MyApp.Domains.CookingDomain do
  use AriaHybridPlanner.Domain

  @type meal_id :: String.t()

  # Simple durative action
  @action duration: "PT2H",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking]},
            %{type: "oven", capabilities: [:heating]}
          ]
  @spec cook_meal(AriaState.t(), [meal_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def cook_meal(state, [meal_id]) do
    state |> AriaState.set_fact("meal_status", meal_id, "ready")
    {:ok, state}
  end
end
```

## Temporal Specification Patterns

**Pattern 1: Instant action, anytime**
```elixir
@action true # Instant action, planner chooses when
```

**Pattern 2: Floating Duration**
```elixir
@action duration: "PT2H" # Takes 2 hours, planner chooses when
```

**Pattern 4: Calculated Start (Deadline)**
```elixir
@action end: "2025-06-22T14:00:00-07:00", duration: "PT2H" # Must start by 12 PM
```

**Pattern 6: Calculated End**
```elixir
@action start: "2025-06-22T10:00:00-07:00", duration: "PT2H"  # Ends at 12 PM
```

**Pattern 7: Fixed Interval**
```elixir
@action start: "2025-06-22T10:00:00-07:00", end: "2025-06-22T12:00:00-07:00"
```

**Pattern 8: Validation**
```elixir
@action start: "2025-06-22T10:00:00-07:00",
        end: "2025-06-22T12:00:00-07:00",
        duration: "PT2H"  # System validates consistency
```

## Function Attribute Requirements

Every planner function MUST have the corresponding attribute:

```elixir
# Actions
@action true
@spec action_name(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}

# Commands
@command true
@spec command_name(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}

# Task Methods
@task_method true
@spec task_name(AriaState.t(), [term()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

# Unigoal Methods
@unigoal_method predicate: "is_predicate"
@spec method_name(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

# Multigoal Methods
@multigoal_method true
@spec multigoal_method(AriaState.t(), AriaEngine.multigoal()) :: {:ok, AriaEngine.multigoal()} | {:error, atom()}

# Multitodo Methods
@multitodo_method true
@spec multitodo_method(AriaState.t(), [AriaEngine.todo_item()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
```

## Capabilities as Traits

Capabilities are simple traits for flexible composition:

```elixir
@type capability :: atom()

# Categories
:agent, :consumable, :tool, :appliance           # Categorical traits
:heating, :cutting, :cooking, :baking            # Behavioral capabilities
:reusable, :portable, :stackable, :container     # Functional traits
:kitchen_equipment, :ingredient, :meeting_space  # Domain-specific
```

## Todo Items vs Domain-Level Optimization Methods

**Important Distinction:** Not all method types are todo_item types.

**Todo Item Types (work items that can be planned and executed):**
```elixir
@type todo_item ::
  task() |                    # {task_name, args} - Composite workflows
  goal() |                    # {predicate, subject, value} - State goals
  AriaEngine.Multigoal.t()    # Multiple coordinated goals
```

**Domain-Level Optimization Methods (NOT todo_items):**
- **@multigoal_method** - Optimizes how multiple goals are solved together
- **@multitodo_method** - Optimizes how todo lists are processed and ordered

These optimization methods operate at the domain/planner level to improve efficiency and coordination, but they are not individual work items that get planned and executed.
