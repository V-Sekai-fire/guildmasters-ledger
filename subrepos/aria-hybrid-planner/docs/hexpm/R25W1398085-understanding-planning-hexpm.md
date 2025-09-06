# R25W1398085: Understanding Planning (HexPM Documentation)

**Status:** Completed
**Date:** 2025-06-28
**Source:** Extracted from unified durative action specification for HexPM documentation

## Why Planning Feels "Backwards"

**Normal Programming (Imperative):**

```elixir
# You control execution directly
def make_dinner() do
  go_to_kitchen()     # Step 1
  get_ingredients()   # Step 2
  cook_meal()        # Step 3
  {:ok, :dinner_made}
end

make_dinner()  # Call when you want it
```

**Planning (Declarative):**

```elixir
# You describe what's possible
@action duration: "PT2H", requires_entities: [
  %{type: "chef", capabilities: [:cooking]}
]
def cook_meal(state, [meal_id]) do
  # Called BY THE PLANNER, not by you
  state |> set_fact("meal_status", meal_id, "ready")
end

# You give goals, planner figures out steps
AriaHybridPlanner.plan(domain, state, [{"meal_status", "dinner", "ready"}])
```

## The Mental Model Shift

**Instead of:** "Do step 1, then step 2, then step 3"
**Think:** "Here are the tools available, here's what I want, figure it out"

## When Planning Scales

**Single Agent (feels overkill):**
- One chef making one meal

**Multiple Agents (planning shines):**
- Restaurant with 5 chefs, 3 ovens, 20 orders
- Automatic resource allocation
- Failure recovery
- Temporal optimization
