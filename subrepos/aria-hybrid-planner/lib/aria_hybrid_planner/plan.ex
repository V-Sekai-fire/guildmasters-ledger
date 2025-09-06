# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaEngineCore.Plan do
  @moduledoc """
  Planning data structures, utilities, and HTN planning implementation for AriaEngine Core.

  This module defines the authoritative solution tree structure and related
  types used throughout the AriaEngine planning system, implementing the
  R25W1398085 unified durative action specification. It also contains the
  core HTN planning implementation with breadth-first decomposition logic.

  ## Key Types

  - `solution_tree()` - Complete planning result with actions, constraints, and metadata
  - `solution_node()` - Individual nodes within the solution tree
  - `todo_item()` - Work items that can be planned and executed

  ## Planning API

      # Plan using HTN planning with proper backtracking support
      {:ok, plan} = AriaEngineCore.Plan.plan(domain, initial_state, todos)

      # Create initial solution tree
      tree = AriaEngineCore.Plan.create_initial_solution_tree(todos, initial_state)

      # Check if solution is complete
      complete? = AriaEngineCore.Plan.solution_complete?(tree)

      # Extract primitive actions for execution
      actions = AriaEngineCore.Plan.get_primitive_actions_dfs(tree)
  """

  require Logger

  # Re-export types from Core module for backward compatibility
  @type task :: AriaEngineCore.Plan.Core.task()
  @type goal :: AriaEngineCore.Plan.Core.goal()
  @type todo_item :: AriaEngineCore.Plan.Core.todo_item()
  @type plan_step :: AriaEngineCore.Plan.Core.plan_step()
  @type node_id :: AriaEngineCore.Plan.Core.node_id()
  @type solution_node :: AriaEngineCore.Plan.Core.solution_node()
  @type solution_tree :: AriaEngineCore.Plan.Core.solution_tree()

  # HTN Planning types
  @type domain :: AriaCore.Domain.t() | map()
  @type state :: AriaState.t()
  @type method_name :: String.t()
  @type plan_result :: {:ok, map()} | {:error, String.t()}

  @doc """
  Plan using IPyHOP-style HTN planning with proper backtracking support.
  Uses iterative refinement with state save/restore for backtracking.
  """
  @spec plan(term(), term(), [term()], keyword()) :: {:ok, map()} | {:error, String.t()}
  def plan(domain, initial_state, todos, opts \\ []) do
    AriaEngineCore.Plan.HTN.plan(domain, initial_state, todos, opts)
  end

  @doc """
  Creates an initial solution tree for the given todo items and initial AriaState.

  ## Parameters

  - `todos` - List of todo items to be planned
  - `initial_state` - Initial world state

  ## Returns

  A new solution tree with a root node containing the todo items.

  ## Example

      todos = [{:cook_meal, ["pasta"]}, {"location", "chef", "kitchen"}]
      state = AriaEngineCore.AriaState.new()
      tree = AriaEngineCore.Plan.create_initial_solution_tree(todos, state)
  """
  @spec create_initial_solution_tree([todo_item()], AriaState.t()) :: solution_tree()
  def create_initial_solution_tree(todos, initial_state) do
    AriaEngineCore.Plan.Core.create_initial_solution_tree(todos, initial_state)
  end

  @doc """
  Generates a unique node identifier.

  ## Returns

  A unique string identifier for a solution tree node.
  """
  @spec generate_node_id() :: String.t()
  def generate_node_id do
    AriaEngineCore.Plan.Core.generate_node_id()
  end

  @doc """
  Checks if a solution tree represents a complete solution.

  A solution is complete when all nodes are expanded and either primitive
  or have children (except for the root node).

  ## Parameters

  - `solution_tree` - The solution tree to check

  ## Returns

  `true` if the solution is complete, `false` otherwise.
  """
  @spec solution_complete?(solution_tree()) :: boolean()
  def solution_complete?(solution_tree) do
    AriaEngineCore.Plan.Core.solution_complete?(solution_tree)
  end

  @doc """
  Updates all cached states in the solution tree with a new AriaState.

  ## Parameters

  - `solution_tree` - The solution tree to update
  - `new_state` - The new state to cache in all nodes

  ## Returns

  Updated solution tree with new cached states.
  """
  @spec update_cached_states(solution_tree(), AriaState.t()) :: solution_tree()
  def update_cached_states(solution_tree, new_state) do
    AriaEngineCore.Plan.Core.update_cached_states(solution_tree, new_state)
  end

  @doc """
  Gets all descendant node IDs for a given node.

  ## Parameters

  - `solution_tree` - The solution tree to search
  - `node_id` - The node ID to find descendants for

  ## Returns

  List of all descendant node IDs.
  """
  @spec get_all_descendants(solution_tree(), node_id()) :: [node_id()]
  def get_all_descendants(solution_tree, node_id) do
    AriaEngineCore.Plan.Core.get_all_descendants(solution_tree, node_id)
  end

  @doc """
  Extracts primitive actions from the solution tree using depth-first search.

  This function traverses the solution tree and collects all primitive actions
  in the order they should be executed.

  ## Parameters

  - `solution_tree` - The solution tree to extract actions from

  ## Returns

  List of plan steps representing the primitive actions to execute.
  """
  @spec get_primitive_actions_dfs(solution_tree()) :: [plan_step()]
  def get_primitive_actions_dfs(solution_tree) do
    AriaEngineCore.Plan.Core.get_actions_from_node(solution_tree, solution_tree.root_id)
  end

  @doc """
  Estimates the cost of a plan (simple step count for now).

  ## Parameters

  - `plan_or_tree` - Either a list of plan steps or a solution tree

  ## Returns

  The number of primitive actions in the plan.
  """
  @spec plan_cost([plan_step()] | solution_tree()) :: non_neg_integer()
  def plan_cost(%{root_id: _} = solution_tree) do
    actions = get_primitive_actions_dfs(solution_tree)
    length(actions)
  end

  def plan_cost(plan) when is_list(plan) do
    length(plan)
  end

  @doc """
  Get statistics about the solution tree.

  ## Parameters

  - `solution_tree` - The solution tree to analyze

  ## Returns

  A map containing various statistics about the tree structure.
  """
  @spec tree_stats(solution_tree()) :: %{
          total_nodes: integer(),
          expanded_nodes: integer(),
          primitive_actions: integer(),
          max_depth: integer()
        }
  def tree_stats(solution_tree) do
    AriaEngineCore.Plan.Core.tree_stats(solution_tree)
  end

  @doc """
  Extracts goals from a solution tree.

  ## Parameters

  - `solution_tree` - The solution tree to extract goals from

  ## Returns

  List of todo items representing the goals.
  """
  @spec get_goals_from_tree(solution_tree()) :: [todo_item()]
  def get_goals_from_tree(solution_tree) do
    AriaEngineCore.Plan.Core.get_goals_from_tree(solution_tree)
  end

  @doc """
  Creates a solution tree from a list of actions.

  ## Parameters

  - `actions` - List of plan steps (actions)
  - `goals` - Original goals that led to these actions
  - `state` - Initial state

  ## Returns

  A solution tree containing the actions as primitive nodes.
  """
  @spec create_solution_tree_from_actions([plan_step()], [todo_item()], AriaState.t()) :: solution_tree()
  def create_solution_tree_from_actions(actions, goals, state) do
    AriaEngineCore.Plan.Core.create_solution_tree_from_actions(actions, goals, state)
  end
end
