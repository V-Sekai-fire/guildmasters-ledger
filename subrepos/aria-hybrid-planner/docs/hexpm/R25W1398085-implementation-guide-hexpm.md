# R25W1398085: Implementation Guide (HexPM Documentation)

**Status:** Completed
**Date:** 2025-06-28
**Source:** Extracted from unified durative action specification for HexPM documentation

## Complete Working Example

```elixir
defmodule MyApp.Domains.CookingDomain do
  use AriaHybridPlanner.Domain

  @type meal_id :: String.t()
  @type ingredient_list :: [String.t()]

  # Entity setup
  @action true
  @spec setup_kitchen_scenario(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def setup_kitchen_scenario(state, []) do
    state
    |> register_entity(["chef_1", "agent", [:cooking, :menu_planning]])
    |> register_entity(["oven_1", "oven", [:heating, :baking]])
    |> register_entity(["main_kitchen_1", "kitchen", [:workspace]])
    |> register_entity(["flour_bag_1", "flour", [:consumable]])
    {:ok, state}
  end

  # Instant actions (zero duration)
  @action duration: "PT0S",
          requires_entities: [%{type: "agent", capabilities: [:observation]}]
  @spec check_ingredients(AriaState.t(), [ingredient_list()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def check_ingredients(state, [ingredient_list]) do
    available_count = Enum.count(ingredient_list, fn ingredient ->
      AriaState.RelationalState.get_fact(state, "available", ingredient) == true
    end)

    state
    |> AriaState.RelationalState.set_fact("ingredients_checked", "kitchen", true)
    |> AriaState.RelationalState.set_fact("available_count", "kitchen", available_count)
    {:ok, state}
  end

  # Durative actions
  @action duration: "PT2H",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking]},
            %{type: "oven", capabilities: [:heating]},
            %{type: "kitchen", capabilities: [:workspace]}
          ]
  @spec cook_meal(AriaState.t(), [meal_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def cook_meal(state, [meal_id]) do
    state
    |> AriaState.RelationalState.set_fact("meal_status", meal_id, "ready")
    |> AriaState.RelationalState.set_fact("chef_status", "chef_1", "available")
    {:ok, state}
  end

  # Task methods for complex workflows
  @task_method true
  @spec prepare_complete_meal(AriaState.t(), [meal_id()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def prepare_complete_meal(state, [meal_id]) do
    {:ok, [
      # Prerequisites as goals
      {"available", "chef_1", true},
      {"temperature", "oven_1", {:>=, 350}},

      # Preparation tasks
      {:setup_workspace, []},
      {:gather_ingredients, [meal_id]},

      # Main cooking action
      {:cook_meal, [meal_id]},

      # Verification goals
      {"quality", meal_id, {:>=, 8}}
    ]}
  end

  # Commands for execution-time logic
  @command true
  @spec cook_meal_command(AriaState.t(), [meal_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def cook_meal_command(state, [meal_id]) do
    case attempt_cooking_with_failure_chance(state, meal_id) do
      {:ok, new_state} ->
        Logger.info("Cooking succeeded for #{meal_id}")
        {:ok, new_state}
      {:error, reason} ->
        Logger.warn("Cooking failed: #{reason}")
        {:error, reason}
    end
  end
end
```

## Usage Patterns

**"I want to see the plan before executing"**

```elixir
case AriaHybridPlanner.plan(domain, state_with_entities, [
  {:cook_meal, ["pasta"]},
  {"location", "chef_1", "kitchen"}
]) do
  {:ok, solution_tree} ->
    IO.inspect(solution_tree, label: "Generated Plan")
    AriaHybridPlanner.run_lazy_tree(domain, state_with_entities, solution_tree)
  {:error, reason} ->
    Logger.error("Planning failed: #{reason}")
end
```

**"I want it done automatically"**

```elixir
case AriaHybridPlanner.run_lazy(domain, state_with_entities, [
  {:cook_meal, ["pasta"]},
  {"location", "chef_1", "kitchen"}
]) do
  {:ok, {final_state, solution_tree}} ->
    Logger.info("Goals achieved successfully!")
    final_state
  {:error, reason} ->
    Logger.error("Planning or execution failed: #{reason}")
end
```

## Best Practices

**1. Keep Actions Simple**
- Pure state transformations only
- No validation logic (planner handles this)
- No failure handling (use commands for that)

**2. Use Method Decomposition for Complexity**
- Prerequisites as goals
- Complex workflows as task methods
- Verification as separate goals

**3. Entity Registration**
- Register all entities before planning
- Include required facts: type, capabilities, status
- Use descriptive entity IDs

**4. Temporal Specifications**
- Use appropriate pattern for your use case
- Prefer floating durations when possible
- Use fixed intervals only when necessary
