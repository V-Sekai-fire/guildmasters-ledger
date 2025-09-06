# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaEngineCore.Plan.HTN do
  @moduledoc """
  HTN (Hierarchical Task Network) planning implementation for AriaEngine Core.

  This module contains the core HTN planning algorithm with breadth-first decomposition logic,
  implementing the IPyHOP-style planning approach with proper backtracking support.
  """

  require Logger

  # Import types from Core module
  @type domain :: AriaCore.Domain.t() | map()
  @type state :: AriaState.t()
  @type method_name :: String.t()
  @type plan_result :: {:ok, map()} | {:error, String.t()}
  @type solution_tree :: AriaEngineCore.Plan.Core.solution_tree()
  @type node_id :: AriaEngineCore.Plan.Core.node_id()
  @type todo_item :: AriaEngineCore.Plan.Core.todo_item()

  @doc """
  Plan using IPyHOP-style HTN planning with proper backtracking support.
  Uses iterative refinement with state save/restore for backtracking.
  """
  @spec plan(term(), term(), [term()], keyword()) :: {:ok, map()} | {:error, String.t()}
  def plan(domain, initial_state, todos, opts \\ []) do
      verbose = Keyword.get(opts, :verbose, 0)
      max_depth = Keyword.get(opts, :max_depth, 100)

      if verbose > 1 do
        Logger.debug("HTN Planning: Starting with #{length(todos)} todos, max_depth: #{max_depth}")
      end

      # Create initial solution tree using the existing approach
      solution_tree = AriaEngineCore.Plan.Core.create_initial_solution_tree(todos, initial_state)

      # Expand the root node to create todo nodes
      case expand_root_node(domain, solution_tree, initial_state, opts) do
        {:ok, expanded_tree} ->
          # Perform HTN planning by expanding nodes one at a time (breadth-first)
          if verbose > 1 do
            Logger.debug("HTN Planning: Starting BFS planning with expanded tree")
            Logger.debug("HTN Planning: Initial tree has #{map_size(expanded_tree.nodes)} nodes")
          end

          case plan_recursive_bfs(domain, expanded_tree, initial_state, opts, 0, max_depth) do
            {:ok, final_tree, final_state} ->
              if verbose > 1 do
                Logger.debug("HTN Planning: BFS planning completed successfully")
              end

              plan = %{
                solution_tree: final_tree,
                metadata: %{
                  created_at: Timex.now() |> Timex.format!("{ISO:Extended}"),
                  domain: domain,
                  final_state: final_state,
                  planning_depth: Keyword.get(opts, :max_depth, 100)
                }
              }

              {:ok, plan}

            {:error, reason} ->
              {:error, reason}
          end

        {:error, reason} ->
          if verbose > 0 do
            Logger.debug("HTN Planning: Failed to expand root: #{inspect(reason)}")
          end
          {:error, reason}
      end
    end

  # Breadth-first HTN planning implementation with IPyHOP-style state management
  @spec plan_recursive_bfs(domain(), solution_tree(), state(), keyword(), non_neg_integer(), non_neg_integer()) ::
    {:ok, solution_tree(), state()} | {:error, String.t()}
  defp plan_recursive_bfs(domain, solution_tree, planning_state, opts, depth, max_depth) do
    verbose = Keyword.get(opts, :verbose, 0)

    if depth >= max_depth do
      if verbose > 1 do
        Logger.debug("HTN Planning: Reached maximum depth #{max_depth}")
      end
      {:ok, solution_tree, planning_state}
    else
      case find_next_unexpanded_node(solution_tree) do
        nil ->
          # All nodes are expanded or primitive
          if verbose > 1 do
            Logger.debug("HTN Planning: No more unexpanded nodes, planning complete")
          end
          {:ok, solution_tree, planning_state}

        node_id ->
          if verbose > 2 do
            Logger.debug("HTN Planning: Expanding node #{node_id} (iteration depth #{depth})")
          end

          case expand_single_node(domain, solution_tree, node_id, planning_state, opts) do
            {:ok, updated_tree, updated_state} ->
              plan_recursive_bfs(domain, updated_tree, updated_state, opts, depth + 1, max_depth)
            {:error, reason} ->
              {:error, reason}
          end
      end
    end
  end

  # Find the next unexpanded node (natural order from map iteration)
  @spec find_next_unexpanded_node(solution_tree()) :: node_id() | nil
  defp find_next_unexpanded_node(solution_tree) do
    Enum.find_value(solution_tree.nodes, fn {id, node} ->
      if not node.expanded and not node.is_primitive do
        id
      else
        nil
      end
    end)
  end

  # Expand a single node based on its type (IPyHOP-style)
  defp expand_single_node(domain, solution_tree, node_id, planning_state, opts) do
    node = solution_tree.nodes[node_id]
    expand_node_by_type(domain, solution_tree, node_id, node, planning_state, opts)
  end

  # Expand a node based on its task type (IPyHOP-style)
  defp expand_node_by_type(domain, solution_tree, node_id, node, planning_state, opts) do
    case node.task do
      # Multigoal expansion
      %AriaEngineCore.Multigoal{} = multigoal ->
        AriaEngineCore.Plan.Methods.expand_multigoal_node(domain, solution_tree, node_id, multigoal, planning_state, opts)

      # Goal expansion (predicate, subject, value)
      {predicate, subject, value} when is_binary(predicate) ->
        AriaEngineCore.Plan.Methods.expand_goal_node(domain, solution_tree, node_id, predicate, subject, value, planning_state, opts)

      # Task expansion (task_name, args) - handle both atoms and strings
      {task_name, args} when is_binary(task_name) or is_atom(task_name) ->
        AriaEngineCore.Plan.Methods.expand_task_node(domain, solution_tree, node_id, to_string(task_name), args, planning_state, opts)

      # Unknown/malformed task type - return error for backtracking
      malformed_task ->
        {:error, "Malformed task format: #{inspect(malformed_task)}"}
    end
  end

  # Expand the root node to create individual todo nodes
  defp expand_root_node(_domain, solution_tree, initial_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    root_node = solution_tree.nodes[solution_tree.root_id]

    case root_node.task do
      {:root, todos} ->
        if verbose > 1 do
          Logger.debug("HTN Planning: Expanding root node with #{length(todos)} todos")
        end

        # Create child nodes for each todo
        AriaEngineCore.Plan.Methods.create_child_nodes(solution_tree, solution_tree.root_id, todos, "root_expansion", initial_state)

      _ ->
        {:error, "Root node does not contain todos"}
    end
  end
end
