# AriaHybridPlanner

A sophisticated Hierarchical Task Network (HTN) planning system with temporal constraint handling, entity management, and IPyHOP integration for Elixir applications.

## Overview

AriaHybridPlanner is a HTN planning system that combines classical AI planning with modern software engineering practices. It provides comprehensive domain management, temporal processing, entity-based resource allocation, and solution tree generation with automatic failure recovery.

### Key Features

- **HTN (Hierarchical Task Network) Planning**: Decompose complex tasks into manageable subtasks
- **Temporal Constraint Handling**: Support for durations, scheduling, and temporal relationships
- **Entity Management**: Resource allocation with capabilities and requirements matching
- **Solution Tree Generation**: Track planning decisions and enable execution replay
- **IPyHOP Integration**: Compatible with Incremental Python Hierarchical Ordered Planner patterns
- **Goal Verification**: Automatic validation of planning goals and constraints
- **State Management**: Relational state representation with fact-based queries
- **Domain Attributes**: Declarative action and method definitions using Elixir attributes

## Installation

Add `aria_hybrid_planner` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:aria_hybrid_planner, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Quick Start

### Basic Planning Example

```elixir
# Create a domain
domain = AriaHybridPlanner.new_domain(:cooking_domain)

# Create initial state
state = AriaHybridPlanner.new_state()
|> AriaHybridPlanner.set_fact("status", "chef_1", "available")
|> AriaHybridPlanner.set_fact("location", "chef_1", "kitchen")

# Define todos (goals to achieve)
todos = [
  {:goal, "meal_prepared", "dinner", "ready"}
]

# Plan and execute
{:ok, {solution_tree, final_state}} = AriaHybridPlanner.run_lazy(domain, state, todos)
```

### Domain Definition with Attributes

```elixir
defmodule CookingDomain do
  use AriaHybridPlanner

  # Define an action with temporal and entity requirements
  @action duration: "PT1H", requires_entities: [
    %{type: "chef", capabilities: [:cooking]},
    %{type: "kitchen", capabilities: [:stove, :oven]}
  ]
  def cook_meal(state, [meal_type]) do
    new_state = AriaHybridPlanner.set_fact(state, "meal_status", meal_type, "cooked")
    {:ok, new_state}
  end

  # Define a task method for meal preparation
  @task_method
  def prepare_dinner(state, [meal_type]) do
    [
      {:action, :gather_ingredients, [meal_type]},
      {:action, :cook_meal, [meal_type]},
      {:action, :plate_meal, [meal_type]}
    ]
  end

  # Define a unigoal method for achieving meal readiness
  @unigoal_method
  def achieve_meal_ready(state, ["meal_prepared", subject, "ready"]) do
    if AriaHybridPlanner.get_fact(state, "meal_status", subject) == {:ok, "cooked"} do
      {:ok, []}  # Goal already achieved
    else
      {:ok, [{:task, :prepare_dinner, [subject]}]}
    end
  end
end
```

### Entity Management

```elixir
# Create entity registry
registry = AriaHybridPlanner.new_entity_registry()

# Register entity types
registry = AriaHybridPlanner.register_entity_type(registry, %{
  type: "chef",
  capabilities: [:cooking, :food_prep],
  properties: %{skill_level: :expert, shift: :day}
})

registry = AriaHybridPlanner.register_entity_type(registry, %{
  type: "kitchen",
  capabilities: [:stove, :oven, :prep_space],
  properties: %{capacity: 4}
})

# Add registry to domain
domain = AriaHybridPlanner.set_entity_registry(domain, registry)
```

### Temporal Processing

```elixir
# Create temporal specifications
specs = AriaHybridPlanner.new_temporal_specifications()

# Add action durations
specs = AriaHybridPlanner.add_action_duration(specs, :cook_meal, 
  AriaHybridPlanner.fixed_duration(3600))  # 1 hour

specs = AriaHybridPlanner.add_action_duration(specs, :prep_ingredients,
  AriaHybridPlanner.variable_duration(900, 1800))  # 15-30 minutes

# Add to domain
domain = AriaHybridPlanner.set_temporal_specifications(domain, specs)
```

## Architecture

### Core Components

1. **Domain Management** (`AriaCore.Domain`): Manages actions, methods, and domain configuration
2. **State Management** (`AriaState`): Relational state representation with fact-based storage
3. **Entity Management** (`AriaCore.Entity.Management`): Resource allocation and capability matching
4. **Temporal Processing** (`AriaCore.Temporal.Interval`): Duration parsing and temporal constraints
5. **Planning Engine** (`AriaEngineCore.Plan`): HTN planning with solution tree generation
6. **Action Attributes** (`AriaCore.ActionAttributes`): Declarative action and method definitions

### Planning Process

1. **Domain Setup**: Define actions, methods, entities, and temporal constraints
2. **State Initialization**: Create initial world state with facts
3. **Goal Specification**: Define todos (goals to achieve)
4. **Planning**: Generate solution tree using HTN decomposition
5. **Execution**: Execute actions in the solution tree
6. **Verification**: Validate goal achievement and constraints

## API Reference

### Primary Planning API

- `plan/4` - Generate a plan with detailed options and solution tree
- `run_lazy/3` - Plan and execute in one step (recommended for most use cases)
- `run_lazy_tree/3` - Execute an existing solution tree

### Domain Management API

- `new_domain/0`, `new_domain/1` - Create new domains
- `add_method/3`, `add_unigoal_method/3` - Add planning methods
- `list_actions/1`, `list_methods/1` - Inspect domain contents
- `validate_domain/1` - Validate domain structure

### Entity Management API

- `new_entity_registry/0` - Create entity registries
- `register_entity_type/2` - Register entity types with capabilities
- `match_entities/2` - Find entities matching requirements

### Temporal Processing API

- `parse_duration/1` - Parse ISO 8601 duration strings
- `fixed_duration/1`, `variable_duration/2` - Create duration specifications
- `add_action_duration/3` - Associate durations with actions

### State Management API

- `new_state/0` - Create new states
- `set_fact/4`, `get_fact/3` - Manage state facts
- `copy_state/1` - Copy states for branching

## Advanced Features

### Goal Verification

Enable automatic goal verification following IPyHOP patterns:

```elixir
domain = AriaHybridPlanner.new_domain(:verified_domain)
domain = AriaHybridPlanner.set_verify_goals(domain, true)
```

### Solution Tree Management

Enable solution tree generation for execution replay and debugging:

```elixir
domain = AriaHybridPlanner.enable_solution_tree(domain, true)
```

### Temporal Constraints

Define complex temporal relationships:

```elixir
# Sequential execution
specs = AriaHybridPlanner.add_temporal_constraint(specs, :cook_meal, 
  {:after, :prep_ingredients})

# Parallel execution with overlap
specs = AriaHybridPlanner.add_temporal_constraint(specs, :plate_meal,
  {:during, :cook_meal, offset: 300})  # Start 5 minutes before cooking ends
```

### Entity Requirements

Specify detailed entity requirements for actions:

```elixir
@action duration: "PT2H", requires_entities: [
  %{type: "surgeon", capabilities: [:cardiac_surgery, :medical_expertise]},
  %{type: "operating_room", capabilities: [:sterile_environment, :heart_lung_machine]},
  %{type: "nurse", capabilities: [:surgical_assistance], count: 2}
]
def perform_cardiac_surgery(state, [patient_id]) do
  # Implementation
end
```

## Testing

Run the test suite:

```bash
mix test
```

Run with coverage:

```bash
mix test --cover
```

## Examples

The `lib/aria_hybrid_planner/examples/` directory contains comprehensive examples:

- **TimelineDomain**: Medical, manufacturing, and software development scenarios
- **UnifiedDomainExamples**: Domain composition and merging patterns

## Dependencies

- **Elixir**: ~> 1.17
- **Timex**: ~> 3.7 (temporal processing)
- **Jason**: ~> 1.4 (JSON serialization)
- **LibGraph**: ~> 0.16 (graph algorithms)
- **Porcelain**: ~> 2.0 (external process execution)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Copyright

Copyright (c) 2025-present K. S. Ernest (iFire) Lee

## Related Projects

- **IPyHOP**: Incremental Python Hierarchical Ordered Planner
- **GTPyhop**: Goal-Task-Pyhop planning framework
- **AriaCore**: Core domain and entity management components
- **AriaState**: Relational state management system

## Support

For questions, issues, or contributions, please visit the [GitHub repository](https://github.com/V-Sekai-fire/aria-hybrid-planner).
