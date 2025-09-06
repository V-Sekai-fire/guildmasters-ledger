# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaEngineCore.Plan.Core do
  @moduledoc """
  Core planning data structures, utilities, and solution tree management for AriaEngine Core.

  This module defines the authoritative solution tree structure and related
  types used throughout the AriaEngine planning system.
  """

  require Logger

  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), AriaState.fact_value()}
  @type todo_item :: task() | goal() | AriaEngineCore.Multigoal.t()
  @type plan_step :: {atom(), list()}
  @type node_id :: String.t()

  @type solution_node :: %{
          id: node_id(),
          task: todo_item(),
          parent_id: node_id() | nil,
          children_ids: [node_id()],
          state: AriaState.t() | nil,
          visited: boolean(),
          expanded: boolean(),
          method_tried: String.t() | nil,
          blacklisted_methods: [String.t()],
          is_primitive: boolean(),
          is_durative: boolean()
        }

  @type solution_tree :: %{
          root_id: node_id(),
          nodes: %{node_id() => solution_node()},
          blacklisted_commands: MapSet.t(),
          goal_network: %{node_id() => [node_id()]}
        }

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
      tree = AriaEngineCore.Plan.Core.create_initial_solution_tree(todos, state)
  """
  @spec create_initial_solution_tree([todo_item()], AriaState.t()) :: solution_tree()
  def create_initial_solution_tree(todos, initial_state) do
    root_id = generate_node_id()

    root_node = %{
      id: root_id,
      task: {:root, todos},
      parent_id: nil,
      children_ids: [],
      state: initial_state,
      visited: false,
      expanded: false,
      method_tried: nil,
      blacklisted_methods: [],
      is_primitive: false,
      is_durative: false
    }

    %{
      root_id: root_id,
      nodes: %{root_id => root_node},
      blacklisted_commands: MapSet.new(),
      goal_network: %{}
    }
  end

  @doc """
  Generates a unique node identifier.

  ## Returns

  A unique string identifier for a solution tree node.
  """
  @spec generate_node_id() :: String.t()
  def generate_node_id do
    "node_#{:erlang.unique_integer([:positive])}"
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
    Enum.all?(solution_tree.nodes, fn {id, node} ->
      is_root = id == solution_tree.root_id
      node.expanded and (node.is_primitive or not Enum.empty?(node.children_ids) or is_root)
    end)
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
    updated_nodes =
      Map.new(solution_tree.nodes, fn {id, node} -> {id, %{node | state: new_state}} end)

    %{solution_tree | nodes: updated_nodes}
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
    case solution_tree.nodes[node_id] do
      nil ->
        []

      node ->
        direct_children = node.children_ids

        all_descendants =
          Enum.flat_map(direct_children, fn child_id ->
            [child_id | get_all_descendants(solution_tree, child_id)]
          end)

        all_descendants
    end
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
    case solution_tree.nodes[solution_tree.root_id] do
      nil -> []
      %{task: {:root, todos}} -> todos
      %{task: task} -> [task]
    end
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
    root_id = generate_node_id()

    # Create root node
    root_node = %{
      id: root_id,
      task: {:root, goals},
      parent_id: nil,
      children_ids: [],
      state: state,
      visited: true,
      expanded: true,
      method_tried: "actions_from_hybrid_planner",
      blacklisted_methods: [],
      is_primitive: false,
      is_durative: false
    }

    # Create action nodes
    {action_nodes, action_ids} =
      Enum.map_reduce(actions, [], fn {action_name, args}, acc_ids ->
        node_id = generate_node_id()

        action_node = %{
          id: node_id,
          task: {action_name, args},
          parent_id: root_id,
          children_ids: [],
          state: state,
          visited: true,
          expanded: true,
          method_tried: nil,
          blacklisted_methods: [],
          is_primitive: true,
          is_durative: false
        }

        {action_node, [node_id | acc_ids]}
      end)

    # Reverse to maintain order
    action_ids = Enum.reverse(action_ids)

    # Update root node with children
    root_node = %{root_node | children_ids: action_ids}

    # Build nodes map
    nodes =
      [root_node | action_nodes]
      |> Enum.map(fn node -> {node.id, node} end)
      |> Map.new()

    %{
      root_id: root_id,
      nodes: nodes,
      blacklisted_commands: MapSet.new(),
      goal_network: %{}
    }
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
  @spec get_actions_from_node(solution_tree(), node_id()) :: [plan_step()]
  def get_actions_from_node(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        []

      node ->
        if node.is_primitive and node.expanded do
          case node.task do
            {action_name, args} ->
              # Convert action name to atom for test compatibility
              action_name_atom = case action_name do
                atom when is_atom(atom) -> atom
                string when is_binary(string) -> String.to_atom(string)
                _ -> String.to_atom(to_string(action_name))
              end
              [{action_name_atom, args}]
            _ -> []
          end
        else
          Enum.flat_map(node.children_ids, fn child_id ->
            get_actions_from_node(solution_tree, child_id)
          end)
        end
    end
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
    nodes = Map.values(solution_tree.nodes)

    %{
      total_nodes: length(nodes),
      expanded_nodes: Enum.count(nodes, & &1.expanded),
      primitive_actions: length(get_actions_from_node(solution_tree, solution_tree.root_id)),
      max_depth: calculate_max_depth(solution_tree, solution_tree.root_id, 0)
    }
  end

  @spec calculate_max_depth(solution_tree(), node_id(), integer()) :: integer()
  defp calculate_max_depth(solution_tree, node_id, current_depth) do
    case solution_tree.nodes[node_id] do
      nil ->
        current_depth

      node ->
        if Enum.empty?(node.children_ids) do
          current_depth
        else
          Enum.map(node.children_ids, fn child_id ->
            calculate_max_depth(solution_tree, child_id, current_depth + 1)
          end)
          |> Enum.max()
        end
    end
  end
end
