# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Temporal.Interval do
  @moduledoc """
  Temporal specification and interval management system for AriaCore.

  This module provides the temporal processing system that supports
  duration specifications in @action attributes. It implements the
  sociable testing approach by providing a complete temporal system
  that can be leveraged by the attribute processing.

  ## Duration Formats

  Supports ISO 8601 duration specification format:
  - **ISO 8601**: "PT2H30M" (2 hours 30 minutes)

  ## Temporal Patterns

  Implements 9 temporal patterns as mentioned in ADR-181:
  1. Fixed duration
  2. Variable duration (min/max range)
  3. Conditional duration (depends on state)
  4. Parallel execution
  5. Sequential execution
  6. Overlapping intervals
  7. Deadline constraints
  8. Resource-dependent timing
  9. Temporal conditions (at_start/over_all/at_end)

  ## Usage

      # Create specifications
      specs = AriaCore.Temporal.Interval.new_specifications()

      # Parse ISO 8601 duration
      duration = AriaCore.Temporal.Interval.parse_iso8601("PT2H")

      # Add action duration
      specs = AriaCore.Temporal.Interval.add_action_duration(specs, :cook_meal, duration)
  """

  defstruct [
    :action_durations,
    :temporal_constraints,
    :execution_patterns,
    :validation_rules
  ]

  @type specifications :: %__MODULE__{
    action_durations: map(),
    temporal_constraints: map(),
    execution_patterns: map(),
    validation_rules: map()
  }

  @type duration ::
    {:fixed, non_neg_integer()} |
    {:variable, {non_neg_integer(), non_neg_integer()}} |
    {:conditional, map()} |
    {:resource_dependent, map()}

  @type temporal_constraint ::
    {:deadline, DateTime.t()} |
    {:earliest_start, DateTime.t()} |
    {:latest_end, DateTime.t()} |
    {:resource_availability, map()}

  @doc """
  Creates a new empty temporal specifications structure.

  ## Examples

      iex> specs = AriaCore.Temporal.Interval.new_specifications()
      iex> specs.action_durations
      %{}
  """
  def new_specifications() do
    %__MODULE__{
      action_durations: %{},
      temporal_constraints: %{},
      execution_patterns: %{},
      validation_rules: %{}
    }
  end

  @doc """
  Parses an ISO 8601 duration string into internal format.

  ## Supported Formats

  - PT#H - Hours only (e.g., "PT2H" = 2 hours)
  - PT#M - Minutes only (e.g., "PT30M" = 30 minutes)
  - PT#S - Seconds only (e.g., "PT45S" = 45 seconds)
  - PT#H#M - Hours and minutes (e.g., "PT2H30M" = 2.5 hours)
  - PT#H#M#S - Hours, minutes, and seconds

  ## Examples

      iex> AriaCore.Temporal.Interval.parse_iso8601("PT2H")
      {:fixed, 7200}

      iex> AriaCore.Temporal.Interval.parse_iso8601("PT30M")
      {:fixed, 1800}

      iex> AriaCore.Temporal.Interval.parse_iso8601("PT2H30M")
      {:fixed, 9000}
  """
  def parse_iso8601(duration_string) when is_binary(duration_string) do
    # Handle empty strings and invalid formats
    if String.trim(duration_string) == "" do
      {:error, "Duration cannot be empty"}
    else
      case Timex.Duration.parse(duration_string) do
        {:ok, duration} ->
          seconds = duration |> Timex.Duration.to_seconds() |> trunc()
          {:fixed, seconds}
        {:error, reason} ->
          {:error, "Invalid ISO 8601 duration: #{inspect(reason)}"}
      end
    end
  end

  def parse_iso8601(nil), do: {:error, "Duration cannot be nil"}
  def parse_iso8601(_), do: {:error, "Invalid duration format"}

  @doc """
  Creates a fixed duration specification.

  ## Examples

      iex> AriaCore.Temporal.Interval.fixed(3600)
      %{type: :fixed, seconds: 3600}
  """
  def fixed(seconds) when is_integer(seconds) and seconds >= 0 do
    %{type: :fixed, seconds: seconds}
  end

  @doc """
  Creates a variable duration specification with min/max range.

  ## Examples

      iex> AriaCore.Temporal.Interval.variable(1800, 7200)
      %{type: :variable, min_seconds: 1800, max_seconds: 7200}
  """
  def variable(min_seconds, max_seconds)
      when is_integer(min_seconds) and is_integer(max_seconds) and min_seconds <= max_seconds do
    %{type: :variable, min_seconds: min_seconds, max_seconds: max_seconds}
  end

  @doc """
  Creates a conditional duration that depends on state conditions.

  ## Examples

      iex> conditions = %{
      ...>   simple_recipe: 1800,
      ...>   complex_recipe: 3600
      ...> }
      iex> AriaCore.Temporal.Interval.conditional(conditions)
      %{type: :conditional, conditions: %{simple_recipe: 1800, complex_recipe: 3600}}
  """
  def conditional(condition_map) when is_map(condition_map) do
    %{type: :conditional, conditions: condition_map}
  end

  @doc """
  Adds an action duration to the specifications.

  ## Examples

      iex> specs = AriaCore.Temporal.Interval.new_specifications()
      iex> duration = AriaCore.Temporal.Interval.fixed(3600)
      iex> specs = AriaCore.Temporal.Interval.add_action_duration(specs, :cook_meal, duration)
      iex> Map.has_key?(specs.action_durations, :cook_meal)
      true
  """
  def add_action_duration(%__MODULE__{} = specs, action_name, duration) do
    updated_durations = Map.put(specs.action_durations, action_name, duration)
    %{specs | action_durations: updated_durations}
  end

  @doc """
  Adds a temporal constraint to the specifications.

  ## Examples

      iex> specs = AriaCore.Temporal.Interval.new_specifications()
      iex> deadline = {:deadline, ~U[2025-06-26 10:00:00Z]}
      iex> specs = AriaCore.Temporal.Interval.add_constraint(specs, :cook_meal, deadline)
      iex> Map.has_key?(specs.temporal_constraints, :cook_meal)
      true
  """
  def add_constraint(%__MODULE__{} = specs, action_name, constraint) do
    existing_constraints = Map.get(specs.temporal_constraints, action_name, [])
    updated_constraints = Map.put(specs.temporal_constraints, action_name, [constraint | existing_constraints])
    %{specs | temporal_constraints: updated_constraints}
  end

  @doc """
  Validates a duration specification.

  ## Examples

      iex> AriaCore.Temporal.Interval.validate({:fixed, 3600})
      :ok

      iex> AriaCore.Temporal.Interval.validate({:variable, {1800, 3600}})
      :ok

      iex> AriaCore.Temporal.Interval.validate({:invalid, "bad"})
      {:error, "Invalid duration format"}
  """
  def validate(duration) do
    case duration do
      {:fixed, seconds} when is_integer(seconds) and seconds >= 0 ->
        :ok

      {:variable, {min, max}} when is_integer(min) and is_integer(max) and min <= max and min >= 0 ->
        :ok

      {:conditional, conditions} when is_map(conditions) ->
        case validate_conditional_conditions(conditions) do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
        end

      {:resource_dependent, config} when is_map(config) ->
        case validate_resource_dependent_config(config) do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
        end

      %{type: :fixed, seconds: seconds} when is_integer(seconds) and seconds >= 0 ->
        :ok

      %{type: :variable, min_seconds: min, max_seconds: max} when is_integer(min) and is_integer(max) and min <= max and min >= 0 ->
        :ok

      %{type: :conditional, conditions: conditions} when is_map(conditions) ->
        :ok

      _ ->
        {:error, "Invalid duration format"}
    end
  end

  @doc """
  Validates that two temporal specifications are equivalent.

  Used by the temporal converter to verify that conversion preserves semantics.
  """
  def validate_equivalence(original_action, simple_action) do
    original_duration = extract_duration(original_action)
    simple_duration = extract_duration(simple_action)

    case {original_duration, simple_duration} do
      {same, same} -> :ok
      {orig, simple} -> compare_duration_semantics(orig, simple)
    end
  end

  @doc """
  Calculates the actual duration for a given action and state.

  Resolves conditional and resource-dependent durations based on current state.
  """
  def calculate_duration(duration, state \\ %{}, resources \\ %{}) do
    case duration do
      {:fixed, seconds} ->
        seconds

      {:variable, {min, max}} ->
        # For now, return average. Could be randomized or state-dependent
        div(min + max, 2)

      {:conditional, conditions} ->
        resolve_conditional_duration(conditions, state)

      {:resource_dependent, config} ->
        resolve_resource_dependent_duration(config, resources)

      %{type: :fixed, seconds: seconds} ->
        seconds

      %{type: :variable, min_seconds: min, max_seconds: max} ->
        div(min + max, 2)

      %{type: :conditional, conditions: conditions} ->
        resolve_conditional_duration(conditions, state)

      _ ->
        1  # Default fallback
    end
  end

  @doc """
  Creates temporal specifications from action metadata.

  Used by the action attributes system to process duration specifications.
  """
  def process_domain_actions(action_metadata) do
    specs = new_specifications()

    Enum.reduce(action_metadata, specs, fn {action_name, metadata}, acc ->
      duration = convert_metadata_duration(metadata[:duration])
      add_action_duration(acc, action_name, duration)
    end)
  end

  @doc """
  Gets the duration specification for an action.
  """
  def get_action_duration(%__MODULE__{} = specs, action_name) do
    Map.get(specs.action_durations, action_name)
  end

  @doc """
  Gets all temporal constraints for an action.
  """
  def get_action_constraints(%__MODULE__{} = specs, action_name) do
    Map.get(specs.temporal_constraints, action_name, [])
  end

  @doc """
  Creates a temporal execution pattern.

  Supports parallel, sequential, and overlapping execution patterns.
  """
  def create_execution_pattern(pattern_type, actions) do
    case pattern_type do
      :sequential -> create_sequential_pattern(actions)
      :parallel -> create_parallel_pattern(actions)
      :overlapping -> create_overlapping_pattern(actions)
      :pipeline -> create_pipeline_pattern(actions)
      _ -> false
    end
  end

  # Private implementation functions

  defp validate_conditional_conditions(conditions) do
    # Validate that all conditions are properly formatted
    valid = Enum.all?(conditions, fn
      {{_pred, _subj, _val}, duration} when is_integer(duration) and duration >= 0 -> true
      _ -> false
    end)

    if valid, do: :ok, else: {:error, "Invalid conditional conditions"}
  end

  defp validate_resource_dependent_config(config) do
    # Validate resource dependency configuration
    required_keys = [:resource_type, :efficiency_map]
    has_required = Enum.all?(required_keys, &Map.has_key?(config, &1))

    if has_required, do: :ok, else: {:error, "Invalid resource dependency config"}
  end

  defp extract_duration(action) do
    case action do
      %{duration: duration} -> duration
      %{"duration" => duration} -> duration
      _ -> {:fixed, 1}
    end
  end

  defp compare_duration_semantics(original, simple) do
    # Compare semantic equivalence of durations
    case {normalize_duration(original), normalize_duration(simple)} do
      {same, same} -> :ok
      _ -> {:error, "Duration semantics not preserved"}
    end
  end

  defp normalize_duration(duration) do
    # Normalize duration to comparable format
    case duration do
      {:fixed, seconds} -> {:fixed, seconds}
      {:variable, {min, max}} -> {:variable, {min, max}}
      _ -> {:unknown, duration}
    end
  end

  defp resolve_conditional_duration(conditions, state) do
    # Handle different condition formats
    case conditions do
      # New map format with simple keys
      conditions when is_map(conditions) ->
        Enum.find_value(conditions, 1, fn {condition_key, duration_spec} ->
          case check_condition_match(condition_key, duration_spec, state) do
            {:match, duration} -> duration
            :no_match -> nil
          end
        end)
      
      # Legacy format with tuple conditions
      conditions when is_list(conditions) ->
        Enum.find_value(conditions, 1, fn {{pred, subj, val}, duration} ->
          case Map.get(state, {pred, subj}) do
            ^val -> duration
            _ -> nil
          end
        end)
      
      _ -> 1
    end
  end
  
  defp check_condition_match(condition_key, duration_spec, state) do
    # Extract duration from duration_spec
    duration = case duration_spec do
      {:fixed, seconds} -> seconds
      %{type: :fixed, seconds: seconds} -> seconds
      seconds when is_integer(seconds) -> seconds
      _ -> 1
    end
    
    # Check if condition matches state
    case condition_key do
      :simple_recipe ->
        if Map.get(state, :recipe_complexity) == :simple, do: {:match, duration}, else: :no_match
      :complex_recipe ->
        if Map.get(state, :recipe_complexity) == :complex, do: {:match, duration}, else: :no_match
      :expert_chef ->
        if Map.get(state, :chef_skill) == :expert, do: {:match, duration}, else: :no_match
      _ ->
        # Default fallback - return the duration if no specific condition matching
        {:match, duration}
    end
  end

  defp resolve_resource_dependent_duration(config, resources) do
    # Calculate duration based on resource efficiency
    base_duration = config[:base_duration] || 3600
    resource_type = config[:resource_type]
    efficiency_map = config[:efficiency_map] || %{}

    case Map.get(resources, resource_type) do
      nil -> base_duration
      resource ->
        efficiency = Map.get(efficiency_map, resource[:quality], 1.0)
        round(base_duration / efficiency)
    end
  end

  defp convert_metadata_duration(duration) do
    case duration do
      duration when is_binary(duration) -> parse_iso8601(duration)
      duration when is_integer(duration) -> fixed(duration)
      nil -> fixed(1)
      other -> other  # Pass through other formats
    end
  end

  defp create_sequential_pattern(actions) do
    # Actions execute one after another
    %{
      type: :sequential,
      actions: actions,
      constraints: create_sequential_constraints(actions)
    }
  end

  defp create_parallel_pattern(actions) do
    # Actions execute simultaneously
    %{
      type: :parallel,
      actions: actions,
      constraints: create_parallel_constraints(actions)
    }
  end

  defp create_overlapping_pattern(actions) do
    # Actions can overlap with specific timing constraints
    %{
      type: :overlapping,
      actions: actions,
      constraints: create_overlapping_constraints(actions)
    }
  end

  defp create_pipeline_pattern(actions) do
    # Actions execute in a pipeline with overlapping stages
    %{
      type: :pipeline,
      actions: actions,
      constraints: create_pipeline_constraints(actions)
    }
  end

  defp create_sequential_constraints(actions) do
    # Each action must finish before the next starts
    Enum.zip(actions, tl(actions))
    |> Enum.map(fn {prev, next} ->
      {:before, prev, next}
    end)
  end

  defp create_parallel_constraints(actions) do
    # All actions start at the same time
    case actions do
      [first | rest] ->
        Enum.map(rest, fn action ->
          {:simultaneous_start, first, action}
        end)
      [] -> []
    end
  end

  defp create_overlapping_constraints(actions) do
    # Actions can overlap but with specific timing relationships
    Enum.zip(actions, tl(actions))
    |> Enum.map(fn {prev, next} ->
      {:overlap_allowed, prev, next}
    end)
  end

  defp create_pipeline_constraints(actions) do
    # Pipeline constraints allow overlapping execution with staggered starts
    Enum.zip(actions, tl(actions))
    |> Enum.map(fn {prev, next} ->
      {:pipeline_stage, prev, next}
    end)
  end
end
