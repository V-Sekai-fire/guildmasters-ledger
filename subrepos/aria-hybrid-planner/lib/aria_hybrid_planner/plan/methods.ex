# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaEngineCore.Plan.Methods do
  @moduledoc """
  Method execution and action handling for HTN planning in AriaEngine Core.

  This module contains the logic for executing methods, handling actions,
  and managing node expansion during HTN planning, implementing IPyHOP-style
  state management and backtracking.
  """

  require Logger

  # Import types from Core module
  @type domain :: AriaCore.Domain.t() | map()
  @type state :: AriaState.t()
  @type solution_tree :: AriaEngineCore.Plan.Core.solution_tree()
  @type node_id :: AriaEngineCore.Plan.Core.node_id()
  @type todo_item :: AriaEngineCore.Plan.Core.todo_item()

  @doc """
  Expand a goal node using unigoal methods (IPyHOP-style)
  """
  @spec expand_goal_node(domain(), solution_tree(), node_id(), String.t(), String.t(), term(), state(), keyword()) ::
    {:ok, solution_tree(), state()} | {:error, String.t()}
  def expand_goal_node(domain, solution_tree, node_id, predicate, subject, value, planning_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    node = solution_tree.nodes[node_id]

    if verbose > 1 do
      Logger.debug("HTN Planning: Expanding goal node #{predicate}(#{subject}, #{value})")
    end

    # Check if goal is already satisfied
    if goal_satisfied?(planning_state, predicate, subject, value) do
      if verbose > 2 do
        Logger.debug("HTN Planning: Goal #{predicate}(#{subject}, #{value}) already satisfied")
      end
      case mark_as_completed(solution_tree, node_id) do
        {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
        error -> error
      end
    else
      # Debug: Check what unigoal methods are available
      if verbose > 1 do
        all_unigoal_methods = AriaHybridPlanner.list_unigoal_methods(domain)
        Logger.debug("HTN Planning: All unigoal methods in domain: #{inspect(all_unigoal_methods)}")

        predicate_methods = AriaHybridPlanner.get_unigoal_methods_for_predicate(domain, predicate)
        Logger.debug("HTN Planning: Unigoal methods for predicate '#{predicate}': #{inspect(predicate_methods)}")
      end

      # Try to expand using unigoal methods
      case try_unigoal_methods(domain, planning_state, predicate, subject, value, node.blacklisted_methods, opts) do
        {:ok, []} ->
          # Method returned empty list - goal completed
          if verbose > 1 do
            Logger.debug("HTN Planning: Unigoal method returned empty list - goal completed")
          end
          case mark_as_completed(solution_tree, node_id) do
            {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
            error -> error
          end

        {:ok, subtasks} ->
          # Create child nodes for subtasks
          if verbose > 1 do
            Logger.debug("HTN Planning: Unigoal method returned #{length(subtasks)} subtasks: #{inspect(subtasks)}")
          end
          case create_child_nodes(solution_tree, node_id, subtasks, "unigoal_method", planning_state) do
            {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
            error -> error
          end

        {:error, reason} ->
          # No methods available - mark as primitive
          if verbose > 1 do
            Logger.debug("HTN Planning: No unigoal methods found for #{predicate}: #{inspect(reason)} - marking as primitive")
          end
          case mark_as_primitive(solution_tree, node_id) do
            {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
            error -> error
          end
      end
    end
  end

  @doc """
  Expand a task node using task methods (IPyHOP-style)
  """
  @spec expand_task_node(domain(), solution_tree(), node_id(), String.t(), list(), state(), keyword()) ::
    {:ok, solution_tree(), state()} | {:error, String.t()}
  def expand_task_node(domain, solution_tree, node_id, task_name, args, planning_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    node = solution_tree.nodes[node_id]

    # Try to expand using task methods
    case try_task_methods(domain, planning_state, task_name, args, node.blacklisted_methods, opts) do
      {:ok, []} ->
        # Method returned empty list - task completed
        if verbose > 2 do
          Logger.debug("HTN Planning: Task #{task_name} completed (empty method result)")
        end
        case mark_as_completed(solution_tree, node_id) do
          {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
          error -> error
        end

      {:ok, subtasks} ->
        # Create child nodes for subtasks
        if verbose > 2 do
          Logger.debug("HTN Planning: Task #{task_name} expanded to #{length(subtasks)} subtasks")
        end
        case create_child_nodes(solution_tree, node_id, subtasks, "task_method", planning_state) do
          {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
          error -> error
        end

      {:error, reason} ->
        # Check if this is a "no methods found" error (primitive action) or "methods failed" error
        cond do
          String.starts_with?(reason, "No task methods found for task") ->
            # No methods found - mark as primitive (can be executed directly)
            if verbose > 2 do
              Logger.debug("HTN Planning: No methods for task #{task_name}, marking as primitive")
            end
            case mark_as_primitive(solution_tree, node_id) do
              {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
              error -> error
            end

          String.starts_with?(reason, "No available methods") ->
            # All available methods were tried and failed - this is an error
            if verbose > 2 do
              Logger.debug("HTN Planning: All methods failed for task #{task_name}: #{inspect(reason)}")
            end
            {:error, "Cannot solve task #{task_name}: #{inspect(reason)}"}

          true ->
            # Custom method error (like precondition not met) - this is an error
            if verbose > 2 do
              Logger.debug("HTN Planning: Method failed for task #{task_name}: #{inspect(reason)}")
            end
            {:error, "Cannot solve task #{task_name}: #{inspect(reason)}"}
        end
    end
  end

  @doc """
  Expand a multigoal node using IPyHOP-style multigoal methods
  """
  @spec expand_multigoal_node(domain(), solution_tree(), node_id(), AriaEngineCore.Multigoal.t(), state(), keyword()) ::
    {:ok, solution_tree(), state()} | {:error, String.t()}
  def expand_multigoal_node(domain, solution_tree, node_id, multigoal, planning_state, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    node = solution_tree.nodes[node_id]

    if verbose > 1 do
      Logger.debug("HTN Planning: Expanding multigoal node with #{length(multigoal.goals)} goals using IPyHOP pattern")
    end

    # Check if all goals are already satisfied
    if all_multigoal_goals_satisfied?(planning_state, multigoal) do
      if verbose > 2 do
        Logger.debug("HTN Planning: All multigoal goals already satisfied")
      end
      case mark_as_completed(solution_tree, node_id) do
        {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
        error -> error
      end
    else
      # Try multigoal methods from domain (IPyHOP pattern)
      case try_multigoal_methods(domain, planning_state, multigoal, node.blacklisted_methods, opts) do
        {:ok, []} ->
          # Method returned empty list - multigoal completed
          if verbose > 1 do
            Logger.debug("HTN Planning: Multigoal method returned empty list - multigoal completed")
          end
          case mark_as_completed(solution_tree, node_id) do
            {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
            error -> error
          end

        {:ok, subtasks} ->
          # Create child nodes for subtasks returned by multigoal method
          if verbose > 1 do
            Logger.debug("HTN Planning: Multigoal method returned #{length(subtasks)} subtasks: #{inspect(subtasks)}")
          end
          case create_child_nodes(solution_tree, node_id, subtasks, "multigoal_method", planning_state) do
            {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
            error -> error
          end

        {:error, reason} ->
          # No multigoal methods available - use default method
          if verbose > 1 do
            Logger.debug("HTN Planning: No domain multigoal methods found: #{inspect(reason)} - using default method")
          end
          case try_default_multigoal_method(planning_state, multigoal, opts) do
            {:ok, []} ->
              # Default method says multigoal is complete
              case mark_as_completed(solution_tree, node_id) do
                {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
                error -> error
              end

            {:ok, subtasks} ->
              # Default method returned subtasks
              if verbose > 2 do
                Logger.debug("HTN Planning: Default multigoal method returned #{length(subtasks)} subtasks")
              end
              case create_child_nodes(solution_tree, node_id, subtasks, "default_multigoal_method", planning_state) do
                {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
                error -> error
              end

            {:error, default_reason} ->
              # Even default method failed - mark as primitive
              if verbose > 1 do
                Logger.debug("HTN Planning: Default multigoal method failed: #{inspect(default_reason)} - marking as primitive")
              end
              case mark_as_primitive(solution_tree, node_id) do
                {:ok, updated_tree} -> {:ok, updated_tree, planning_state}
                error -> error
              end
          end
      end
    end
  end

  @doc """
  Mark a node as primitive (completed action)
  """
  @spec mark_as_primitive(solution_tree(), node_id()) :: {:ok, solution_tree()} | {:error, String.t()}
  def mark_as_primitive(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node #{node_id} not found"}

      node ->
        updated_node = %{node |
          is_primitive: true,
          expanded: true,
          visited: true
        }

        updated_nodes = Map.put(solution_tree.nodes, node_id, updated_node)
        updated_tree = %{solution_tree | nodes: updated_nodes}
        {:ok, updated_tree}
    end
  end

  @doc """
  Mark a node as completed (goal satisfied or empty method result)
  """
  @spec mark_as_completed(solution_tree(), node_id()) :: {:ok, solution_tree()} | {:error, String.t()}
  def mark_as_completed(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node #{node_id} not found"}

      node ->
        updated_node = %{node |
          expanded: true,
          visited: true
        }

        updated_nodes = Map.put(solution_tree.nodes, node_id, updated_node)
        updated_tree = %{solution_tree | nodes: updated_nodes}
        {:ok, updated_tree}
    end
  end

  @doc """
  Create child nodes from subtasks (IPyHOP-style - no state progression)
  """
  @spec create_child_nodes(solution_tree(), node_id(), list(), String.t(), state()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  def create_child_nodes(solution_tree, parent_node_id, subtasks, method_name, planning_state) do
    parent_node = solution_tree.nodes[parent_node_id]

    # Generate child nodes without state progression (IPyHOP approach)
    {child_nodes, child_ids} = subtasks
    |> Enum.with_index()
    |> Enum.reduce({[], []}, fn {subtask, index}, {nodes_acc, ids_acc} ->
      child_id = "#{parent_node_id}_#{method_name}_#{index}"

      child_node = %{
        id: child_id,
        task: subtask,
        parent_id: parent_node_id,
        children_ids: [],
        state: planning_state,  # All children start with current planning state
        visited: false,
        expanded: false,
        method_tried: nil,
        blacklisted_methods: [],
        is_primitive: false,
        is_durative: false
      }

      {[{child_id, child_node} | nodes_acc], [child_id | ids_acc]}
    end)

    # Reverse to maintain correct order
    child_nodes = Enum.reverse(child_nodes)
    child_ids = Enum.reverse(child_ids)

    # Update parent node
    updated_parent = %{parent_node |
      method_tried: method_name,
      expanded: true,
      children_ids: child_ids
    }

    # Update solution tree
    updated_nodes = child_nodes
    |> Enum.into(solution_tree.nodes)
    |> Map.put(parent_node_id, updated_parent)

    updated_tree = %{solution_tree | nodes: updated_nodes}
    {:ok, updated_tree}
  end

  # Try unigoal methods for a goal
  defp try_unigoal_methods(domain, state, predicate, subject, value, blacklisted_methods, opts) do
    case AriaHybridPlanner.get_unigoal_methods_for_predicate(domain, predicate) do
      methods when map_size(methods) > 0 ->
        # Try each method that isn't blacklisted
        available_methods = methods
        |> Enum.reject(fn {method_name, _} ->
          method_name_str = case method_name do
            atom when is_atom(atom) -> Atom.to_string(atom)
            string when is_binary(string) -> string
            other -> to_string(other)
          end
          method_name_str in blacklisted_methods
        end)

        try_methods_sequentially(available_methods, state, {subject, value}, opts)

      _ ->
        {:error, "No unigoal methods found for predicate #{predicate}"}
    end
  end

  # Try task methods for a task
  defp try_task_methods(domain, state, task_name, args, blacklisted_methods, opts) do
    case AriaHybridPlanner.get_task_methods_from_domain(domain, task_name) do
      methods when is_list(methods) and length(methods) > 0 ->
        # Try each method that isn't blacklisted
        available_methods = methods
        |> Enum.reject(fn {method_name, _} ->
          method_name_str = case method_name do
            atom when is_atom(atom) -> Atom.to_string(atom)
            string when is_binary(string) -> string
            other -> to_string(other)
          end
          method_name_str in blacklisted_methods
        end)

        try_methods_sequentially(available_methods, state, args, opts)

      _ ->
        {:error, "No task methods found for task #{task_name}"}
    end
  end

  # Try methods sequentially until one succeeds
  defp try_methods_sequentially([], _state, _args, _opts) do
    {:error, "No available methods"}
  end

  defp try_methods_sequentially([{method_name, method_spec} | rest], state, args, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Planning: Trying method #{inspect(method_name)} with args #{inspect(args)}")
    end

    try do
      # Handle different method spec formats
      result = case method_spec do
        # Unigoal method spec with goal_fn
        %{goal_fn: goal_fn} when is_function(goal_fn) ->
          goal_fn.(state, args)

        # Direct function reference (task methods)
        method_fn when is_function(method_fn) ->
          method_fn.(state, args)

        # Other spec formats
        _ ->
          {:error, "Invalid method spec format: #{inspect(method_spec)}"}
      end

      if verbose > 2 do
        Logger.debug("HTN Planning: Method #{inspect(method_name)} returned: #{inspect(result)}")
      end

      case result do
        subtasks when is_list(subtasks) ->
          {:ok, subtasks}
        {:ok, subtasks} when is_list(subtasks) ->
          {:ok, subtasks}
        {:error, reason} ->
          if verbose > 2 do
            Logger.debug("HTN Planning: Method #{inspect(method_name)} failed: #{inspect(reason)}")
          end
          try_methods_sequentially(rest, state, args, opts)
        other ->
          if verbose > 2 do
            Logger.debug("HTN Planning: Method #{inspect(method_name)} returned unexpected result: #{inspect(other)}")
          end
          try_methods_sequentially(rest, state, args, opts)
      end
    rescue
      e ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Method #{inspect(method_name)} raised exception: #{inspect(e)}")
        end
        try_methods_sequentially(rest, state, args, opts)
    end
  end



  # Check if a goal is satisfied in the current state
  defp goal_satisfied?(state, predicate, subject, value) do
    # Use AriaState to check if the goal is satisfied
    AriaState.matches?(state, predicate, subject, value)
  end

  # Try default multigoal method (IPyHOP pattern)
  defp try_default_multigoal_method(state, multigoal, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Planning: Trying default multigoal method")
    end

    try do
      # Use the default multigoal method from AriaCore
      result = AriaCore.DefaultMultigoalMethod.default_multigoal_method(state, multigoal)

      if verbose > 2 do
        Logger.debug("HTN Planning: Default multigoal method returned: #{inspect(result)}")
      end

      {:ok, result}
    rescue
      e ->
        if verbose > 1 do
          Logger.debug("HTN Planning: Default multigoal method raised exception: #{inspect(e)}")
        end
        {:error, "Default multigoal method failed: #{inspect(e)}"}
    end
  end

  # Check if all goals in a multigoal are satisfied
  defp all_multigoal_goals_satisfied?(state, multigoal) do
    Enum.all?(multigoal.goals, fn {predicate, subject, value} ->
      goal_satisfied?(state, predicate, subject, value)
    end)
  end

  # Try multigoal methods from domain (IPyHOP pattern)
  defp try_multigoal_methods(domain, state, multigoal, blacklisted_methods, opts) do
    case AriaHybridPlanner.get_multigoal_methods_from_domain(domain) do
      methods when is_list(methods) and length(methods) > 0 ->
        # Try each method that isn't blacklisted
        available_methods = methods
        |> Enum.reject(fn {method_name, _} ->
          method_name_str = case method_name do
            atom when is_atom(atom) -> Atom.to_string(atom)
            string when is_binary(string) -> string
            other -> to_string(other)
          end
          method_name_str in blacklisted_methods
        end)

        try_multigoal_methods_sequentially(available_methods, state, multigoal, opts)

      _ ->
        {:error, "No multigoal methods found in domain"}
    end
  end

  # Try multigoal methods sequentially until one succeeds
  defp try_multigoal_methods_sequentially([], _state, _multigoal, _opts) do
    {:error, "No available multigoal methods"}
  end

  defp try_multigoal_methods_sequentially([{method_name, method_fn} | rest], state, multigoal, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("HTN Planning: Trying multigoal method #{inspect(method_name)}")
    end

    try do
      # Call multigoal method with state and complete multigoal object (IPyHOP pattern)
      result = method_fn.(state, multigoal)

      if verbose > 2 do
        Logger.debug("HTN Planning: Multigoal method #{inspect(method_name)} returned: #{inspect(result)}")
      end

      case result do
        subtasks when is_list(subtasks) ->
          {:ok, subtasks}
        {:ok, subtasks} when is_list(subtasks) ->
          {:ok, subtasks}
        {:error, reason} ->
          if verbose > 2 do
            Logger.debug("HTN Planning: Multigoal method #{inspect(method_name)} failed: #{inspect(reason)}")
          end
          try_multigoal_methods_sequentially(rest, state, multigoal, opts)
        other ->
          if verbose > 2 do
            Logger.debug("HTN Planning: Multigoal method #{inspect(method_name)} returned unexpected result: #{inspect(other)}")
          end
          try_multigoal_methods_sequentially(rest, state, multigoal, opts)
      end
    rescue
      e ->
        if verbose > 2 do
          Logger.debug("HTN Planning: Multigoal method #{inspect(method_name)} raised exception: #{inspect(e)}")
        end
        try_multigoal_methods_sequentially(rest, state, multigoal, opts)
    end
  end
end
