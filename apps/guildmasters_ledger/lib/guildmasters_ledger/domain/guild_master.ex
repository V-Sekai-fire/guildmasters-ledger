# Temporarily disabled for benchmarking
# defmodule GuildmastersLedger.Domain.GuildMaster do
  @moduledoc """
  Guild Master Domain for HTN Planning

  This module implements the Guild Master domain using the Aria Hybrid Planner.
  It defines actions, methods, and goals for autonomous hero management in
  the Guildmaster's Ledger game.

  Based on R25W1398085: Unified Durative Action Specification
  """

  use AriaHybridPlanner.Domain

  alias GuildmastersLedger.Persistence

  @type hero_id :: String.t()
  @type quest_id :: String.t()
  @type location_id :: String.t()

  # Entity registration - setup the game world
  @action true
  @spec setup_guild_scenario(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def setup_guild_scenario(state, []) do
    state
    |> register_entity(["hero_1", "hero", [:adventuring, :fighting, :exploring]])
    |> register_entity(["guild_hall", "location", [:safe, :base]])
    |> register_entity(["goblin_cave", "location", [:dangerous, :monster_infested]])
    |> register_entity(["forest_clearing", "location", [:neutral, :resource_rich]])
    {:ok, state}
  end

  # Hero movement action
  @action duration: "PT30M",
          requires_entities: [
            %{type: "hero", capabilities: [:adventuring]}
          ]
  @spec move_to_location(AriaState.t(), [hero_id(), location_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def move_to_location(state, [hero_id, location_id]) do
    # Update persistence layer
    :ok = Persistence.set_fact("location", hero_id, location_id)
    :ok = Persistence.set_fact("hero_status", hero_id, "traveling")

    # Return updated state for planner compatibility
    {:ok, state}
  end

  # Quest execution action
  @action duration: "PT2H",
          requires_entities: [
            %{type: "hero", capabilities: [:fighting]},
            %{type: "location", capabilities: [:dangerous]}
          ]
  @spec execute_quest(AriaState.t(), [quest_id(), hero_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def execute_quest(state, [quest_id, hero_id]) do
    # Simulate quest completion with random success
    if :rand.uniform() > 0.2 do  # 80% success rate
      # Update persistence layer
      :ok = Persistence.set_fact("quest_status", quest_id, "completed")
      :ok = Persistence.set_fact("hero_status", hero_id, "available")
      current_gold = Persistence.get_fact("guild_gold", "guild") || 0
      :ok = Persistence.set_fact("guild_gold", "guild", current_gold + 100)
    else
      :ok = Persistence.set_fact("quest_status", quest_id, "failed")
      :ok = Persistence.set_fact("hero_status", hero_id, "injured")
    end
    {:ok, state}
  end

  # Quest acceptance action
  @action true
  @spec accept_quest(AriaState.t(), [quest_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def accept_quest(state, [quest_id]) do
    # Update persistence layer
    :ok = Persistence.set_fact("quest_status", quest_id, "accepted")
    :ok = Persistence.set_fact("quest_accepted_at", quest_id, DateTime.utc_now())

    {:ok, state}
  end

  # Complex quest workflow using task methods
  @task_method true
  @spec complete_quest_workflow(AriaState.t(), [quest_id(), hero_id()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def complete_quest_workflow(state, [quest_id, hero_id]) do
    quest_location = get_quest_location(quest_id)

    {:ok, [
      # Prerequisites
      {"hero_status", hero_id, "available"},
      {"quest_status", quest_id, "accepted"},

      # Quest execution steps
      {:accept_quest, [quest_id]},
      {:move_to_location, [hero_id, quest_location]},
      {:execute_quest, [quest_id, hero_id]},
      {:move_to_location, [hero_id, "guild_hall"]},

      # Success verification
      {"quest_status", quest_id, "completed"}
    ]}
  end

  # Unigoal method for hero availability
  @unigoal_method predicate: "hero_status"
  @spec make_hero_available(AriaState.t(), {hero_id(), String.t()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def make_hero_available(state, {hero_id, "available"}) do
    current_status = Persistence.get_fact("hero_status", hero_id)

    case current_status do
      "available" -> {:ok, []}  # Already available
      "injured" -> {:ok, [{:heal_hero, [hero_id]}]}
      "traveling" -> {:ok, [{:wait_for_hero, [hero_id]}]}
      _ -> {:ok, [{:reset_hero_status, [hero_id]}]}
    end
  end

  # Domain creation
  @spec create_domain() :: AriaHybridPlanner.Domain.t()
  def create_domain do
    domain = __MODULE__.create_base_domain()
    domain = AriaHybridPlanner.Domain.set_verify_goals(domain, true)
    domain = %{domain | blacklist: MapSet.new()}
    AriaHybridPlanner.Domain.enable_solution_tree(domain, true)
  end

  # Helper functions
  defp register_entity(state, [entity_id, type, capabilities]) do
    # Update persistence layer
    :ok = Persistence.set_fact("type", entity_id, type)
    :ok = Persistence.set_fact("capabilities", entity_id, capabilities)
    :ok = Persistence.set_fact("status", entity_id, "available")

    # Return state unchanged for compatibility
    state
  end

  defp get_gold(_state) do
    Persistence.get_fact("guild_gold", "guild") || 0
  end

  defp get_quest_location(_quest_id) do
    # In a real implementation, this would look up the quest location
    "goblin_cave"
  end
end
