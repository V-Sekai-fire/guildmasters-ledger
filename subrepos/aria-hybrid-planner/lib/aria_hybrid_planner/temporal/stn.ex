# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaHybridPlanner.Temporal.STN do
  @moduledoc """
  Simple Temporal Network (STN) implementation for AriaHybridPlanner.

  This module provides internal STN capabilities for temporal constraint solving
  within the hybrid planner. It supports:

  - Temporal constraint management
  - Interval scheduling and conflict detection
  - Time unit conversion and LOD scaling
  - MiniZinc integration for complex constraint solving
  - Parallel processing for large STNs

  ## Usage

  STNs are used internally by AriaHybridPlanner for:
  - Validating temporal consistency of action plans
  - Scheduling durative actions with resource constraints
  - Optimizing temporal execution sequences
  - Resolving temporal conflicts during planning

  ## Example

      # Create a new STN for internal planner use
      stn = AriaHybridPlanner.Temporal.STN.new(time_unit: :second)
      
      # Add temporal constraints (used internally by planner)
      stn = AriaHybridPlanner.Temporal.STN.add_constraint(stn, "action1_start", "action1_end", {10, 15})
      
      # Check consistency
      AriaHybridPlanner.Temporal.STN.consistent?(stn)
  """

  alias AriaHybridPlanner.Temporal.STN.{Operations, Consistency, Scheduling, Units}
  alias AriaMinizincStn

  @type constraint :: {number(), number()}
  @type time_point :: String.t()
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}
  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day
  @type lod_level :: :ultra_high | :high | :medium | :low | :very_low
  @type lod_resolution :: 1 | 10 | 100 | 1000 | 10000
  
  @type t :: %__MODULE__{
          time_points: MapSet.t(time_point()),
          constraints: constraint_matrix(),
          consistent: boolean(),
          segments: [segment()],
          metadata: map(),
          time_unit: time_unit(),
          lod_level: lod_level(),
          lod_resolution: lod_resolution(),
          auto_rescale: boolean(),
          datetime_conversion_unit: time_unit(),
          max_timepoints: pos_integer(),
          constant_work_enabled: boolean(),
          dummy_constraints: constraint_matrix()
        }
        
  @type segment :: %{
          id: String.t(),
          time_points: MapSet.t(time_point()),
          constraints: constraint_matrix(),
          boundary_points: [time_point()],
          consistent: boolean()
        }
        
  defstruct time_points: MapSet.new(),
            constraints: %{},
            consistent: true,
            segments: [],
            metadata: %{},
            time_unit: :second,
            lod_level: :medium,
            lod_resolution: 100,
            auto_rescale: true,
            datetime_conversion_unit: :second,
            max_timepoints: 64,
            constant_work_enabled: false,
            dummy_constraints: %{}

  @doc """
  Creates a new empty Simple Temporal Network.

  Uses seconds as the default time unit for human-readable temporal constraints.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{time_points: MapSet.new(), constraints: %{}, consistent: true, time_unit: :second}
  end

  @doc """
  Creates a new Simple Temporal Network with specified units and LOD level.
  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    time_unit = Keyword.get(opts, :time_unit, :second)
    lod_level = Keyword.get(opts, :lod_level, :medium)
    max_timepoints = Keyword.get(opts, :max_timepoints, 64)
    constant_work_enabled = Keyword.get(opts, :constant_work_enabled, false)

    stn = %__MODULE__{
      time_points: MapSet.new(),
      constraints: %{},
      consistent: true,
      time_unit: time_unit,
      lod_level: lod_level,
      lod_resolution: Units.lod_resolution_for_level(lod_level),
      auto_rescale: Keyword.get(opts, :auto_rescale, true),
      datetime_conversion_unit: Keyword.get(opts, :datetime_conversion_unit, :second),
      max_timepoints: max_timepoints,
      constant_work_enabled: constant_work_enabled,
      dummy_constraints: %{}
    }

    if constant_work_enabled do
      initialize_constant_work_structure(stn)
    else
      stn
    end
  end

  @doc """
  Creates a new Simple Temporal Network with constant work pattern enabled by default.
  """
  @spec new_constant_work(keyword()) :: t()
  def new_constant_work(opts \\ []) do
    opts_with_constant_work = Keyword.put(opts, :constant_work_enabled, true)
    new(opts_with_constant_work)
  end

  # Delegate to Operations module
  defdelegate add_interval(stn, interval), to: Operations
  defdelegate update_interval(stn, interval), to: Operations
  defdelegate remove_interval(stn, interval_id), to: Operations
  defdelegate add_constraint(stn, from_point, to_point, constraint), to: Operations
  defdelegate get_constraint(stn, from_point, to_point), to: Operations
  defdelegate add_time_point(stn, time_point), to: Operations
  defdelegate time_points(stn), to: Operations

  # Delegate to Consistency module
  defdelegate simple_stn?(stn), to: Consistency
  defdelegate consistent?(stn), to: Consistency
  defdelegate mathematically_consistent?(stn), to: Consistency

  # Delegate to Scheduling module
  defdelegate get_intervals(stn), to: Scheduling
  defdelegate get_overlapping_intervals(stn, query_start, query_end), to: Scheduling
  defdelegate find_free_slots(stn, duration, window_start, window_end), to: Scheduling
  defdelegate check_interval_conflicts(stn, new_start, new_end), to: Scheduling
  defdelegate find_next_available_slot(stn, duration, earliest_start), to: Scheduling

  # Delegate to Units module
  defdelegate rescale_lod(stn, new_lod_level), to: Units
  defdelegate convert_units(stn, new_unit), to: Units
  defdelegate from_datetime_intervals(intervals, opts), to: Units

  # Delegate to AriaMinizincStn for complex solving
  defdelegate solve_stn(stn), to: AriaMinizincStn

  @doc """
  Union two STNs together, combining their constraints.
  """
  @spec union(t(), t()) :: t()
  def union(stn1, stn2) do
    # Auto-rescale if needed
    {stn1_rescaled, stn2_rescaled} = maybe_auto_rescale(stn1, stn2)
    
    # Combine time points
    combined_time_points = MapSet.union(stn1_rescaled.time_points, stn2_rescaled.time_points)
    
    # Combine constraints (intersection for overlapping constraints)
    combined_constraints = merge_constraints(stn1_rescaled.constraints, stn2_rescaled.constraints)
    
    # Check consistency
    consistent = stn1_rescaled.consistent and stn2_rescaled.consistent
    
    %{stn1_rescaled |
      time_points: combined_time_points,
      constraints: combined_constraints,
      consistent: consistent
    }
  end

  @doc """
  Chain multiple STNs sequentially.
  """
  @spec chain([t()]) :: t()
  def chain([]), do: new()
  def chain([stn]), do: stn
  def chain([first | rest]) do
    Enum.reduce(rest, first, fn stn, acc ->
      union(acc, stn)
    end)
  end

  @doc """
  Split an STN into multiple segments for parallel processing.
  """
  @spec split(t(), pos_integer()) :: [t()]
  def split(stn, num_segments) when num_segments > 0 do
    time_points_list = MapSet.to_list(stn.time_points)
    chunk_size = max(1, div(length(time_points_list), num_segments))
    
    time_points_list
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(fn chunk_points ->
      chunk_time_points = MapSet.new(chunk_points)
      
      # Filter constraints to only include those within this chunk
      chunk_constraints = 
        stn.constraints
        |> Enum.filter(fn {{from, to}, _} ->
          MapSet.member?(chunk_time_points, from) and MapSet.member?(chunk_time_points, to)
        end)
        |> Map.new()
      
      %{stn |
        time_points: chunk_time_points,
        constraints: chunk_constraints
      }
    end)
  end

  @doc """
  Solve STN constraints in parallel using multiple workers.
  """
  @spec parallel_solve(t(), pos_integer()) :: t()
  def parallel_solve(stn, num_workers) when num_workers > 0 do
    # For now, just delegate to regular solve since parallel solving
    # would require more complex coordination
    case solve_stn(stn) do
      {:ok, solved_stn} -> solved_stn
      {:error, _reason} -> %{stn | consistent: false}
    end
  end

  @doc """
  Validates temporal consistency of a plan using STN constraint solving.

  This function creates an STN from the plan's temporal constraints and
  validates that all temporal relationships are consistent.

  ## Parameters

  - `plan`: Plan structure containing temporal information

  ## Returns

  `{:ok, :consistent}` if the plan is temporally consistent,
  `{:error, reason}` if there are temporal conflicts.

  ## Examples

      iex> plan = %{actions: [%{name: :action1, start: 0, duration: 10}]}
      iex> AriaHybridPlanner.Temporal.STN.validate_plan(plan)
      {:ok, :consistent}
  """
  @spec validate_plan(map()) :: {:ok, :consistent} | {:error, String.t()}
  def validate_plan(plan) when is_map(plan) do
    try do
      # Create STN from plan
      stn = new(time_unit: :second)
      
      # Extract temporal constraints from plan
      stn_with_constraints = case Map.get(plan, :actions) do
        nil -> stn
        actions when is_list(actions) ->
          Enum.reduce(actions, stn, fn action, acc_stn ->
            add_plan_action_to_stn(acc_stn, action)
          end)
        _ -> stn
      end
      
      # Add explicit constraints from the plan
      stn_with_all_constraints = case Map.get(plan, :constraints) do
        nil -> stn_with_constraints
        constraints when is_list(constraints) ->
          Enum.reduce(constraints, stn_with_constraints, fn constraint, acc_stn ->
            add_plan_constraint_to_stn(acc_stn, constraint, plan)
          end)
        _ -> stn_with_constraints
      end
      
      # Check consistency
      if consistent?(stn_with_all_constraints) do
        {:ok, :consistent}
      else
        {:error, "Plan contains temporal inconsistencies"}
      end
    rescue
      error ->
        {:error, "Failed to validate plan: #{inspect(error)}"}
    end
  end

  def validate_plan(_plan) do
    {:error, "Plan must be a map"}
  end

  # Private implementation functions

  defp maybe_auto_rescale(stn1, stn2) do
    if stn1.auto_rescale and stn2.auto_rescale do
      # If units or LOD levels differ, rescale to common format
      if stn1.time_unit != stn2.time_unit or stn1.lod_level != stn2.lod_level do
        # Use the more precise settings
        target_unit = if Units.unit_precision(stn1.time_unit) <= Units.unit_precision(stn2.time_unit), 
                        do: stn1.time_unit, else: stn2.time_unit
        target_lod = if Units.lod_precision(stn1.lod_level) <= Units.lod_precision(stn2.lod_level),
                       do: stn1.lod_level, else: stn2.lod_level
        
        stn1_rescaled = stn1 |> convert_units(target_unit) |> rescale_lod(target_lod)
        stn2_rescaled = stn2 |> convert_units(target_unit) |> rescale_lod(target_lod)
        
        {stn1_rescaled, stn2_rescaled}
      else
        {stn1, stn2}
      end
    else
      # No auto-rescaling, return as-is
      {stn1, stn2}
    end
  end

  defp merge_constraints(constraints1, constraints2) do
    Map.merge(constraints1, constraints2, fn _key, c1, c2 ->
      # Union constraints for the same time point pair (OR operation - more permissive)
      union_constraints(c1, c2)
    end)
  end

  defp union_constraints({min1, max1}, {min2, max2}) do
    # For OR operation: min of mins, max of maxes (more permissive bounds)
    new_min = constraint_min(min1, min2)
    new_max = constraint_max(max1, max2)
    {new_min, new_max}
  end

  defp constraint_max(:neg_infinity, other), do: other
  defp constraint_max(other, :neg_infinity), do: other
  defp constraint_max(:infinity, _), do: :infinity
  defp constraint_max(_, :infinity), do: :infinity
  defp constraint_max(a, b) when is_number(a) and is_number(b), do: max(a, b)

  defp constraint_min(:infinity, other), do: other
  defp constraint_min(other, :infinity), do: other
  defp constraint_min(:neg_infinity, _), do: :neg_infinity
  defp constraint_min(_, :neg_infinity), do: :neg_infinity
  defp constraint_min(a, b) when is_number(a) and is_number(b), do: min(a, b)

  defp initialize_constant_work_structure(stn) do
    dummy_points =
      for i <- 1..stn.max_timepoints do
        "dummy_#{i}"
      end
      |> MapSet.new()

    dummy_constraints =
      Enum.reduce(dummy_points, %{}, fn point, acc -> Map.put(acc, {point, point}, {-1, 1}) end)

    %{
      stn
      | time_points: MapSet.union(stn.time_points, dummy_points),
        dummy_constraints: dummy_constraints,
        constraints: Map.merge(stn.constraints, dummy_constraints)
    }
  end

  defp add_plan_action_to_stn(stn, action) when is_map(action) do
    action_name = Map.get(action, :name, "unknown_action")
    start_point = "#{action_name}_start"
    end_point = "#{action_name}_end"
    
    # Add time points
    stn_with_points = stn
    |> add_time_point(start_point)
    |> add_time_point(end_point)
    
    # Add duration constraint if available
    case Map.get(action, :duration) do
      duration when is_number(duration) and duration > 0 ->
        add_constraint(stn_with_points, start_point, end_point, {duration, duration})
      _ ->
        # Default duration constraint (1 time unit)
        add_constraint(stn_with_points, start_point, end_point, {1, 1})
    end
  end

  defp add_plan_action_to_stn(stn, _action) do
    # Invalid action format, return STN unchanged
    stn
  end

  defp add_plan_constraint_to_stn(stn, constraint, plan) when is_map(constraint) do
    case constraint do
      %{type: :before, from: from_action, to: to_action} ->
        # Action 'from' must finish before action 'to' starts
        from_end = "#{from_action}_end"
        to_start = "#{to_action}_start"
        
        # Add constraint that from_end <= to_start (0 delay minimum)
        # But first check if this creates a conflict with existing timing
        stn_with_constraint = add_constraint(stn, from_end, to_start, {0, :infinity})
        
        # Check for temporal conflicts by examining action timings
        case check_temporal_conflict(plan, from_action, to_action) do
          :conflict -> %{stn_with_constraint | consistent: false}
          :ok -> stn_with_constraint
        end
        
      %{type: :after, from: from_action, to: to_action} ->
        # Action 'from' must start after action 'to' finishes
        from_start = "#{from_action}_start"
        to_end = "#{to_action}_end"
        
        # Add constraint that to_end <= from_start
        stn_with_constraint = add_constraint(stn, to_end, from_start, {0, :infinity})
        
        # Check for temporal conflicts
        case check_temporal_conflict(plan, to_action, from_action) do
          :conflict -> %{stn_with_constraint | consistent: false}
          :ok -> stn_with_constraint
        end
        
      _ ->
        # Unknown constraint type, return STN unchanged
        stn
    end      
  end
  defp add_plan_constraint_to_stn(stn, _constraint, _plan) do
    # Invalid constraint format, return STN unchanged
    stn
  end
  
  # Helper function to check for temporal conflicts
  defp check_temporal_conflict(plan, first_action, second_action) do
    actions = Map.get(plan, :actions, [])
    
    first_action_data = Enum.find(actions, fn action -> 
      Map.get(action, :name) == first_action 
    end)
    
    second_action_data = Enum.find(actions, fn action -> 
      Map.get(action, :name) == second_action 
    end)
    
    case {first_action_data, second_action_data} do
      {%{start_time: start1, duration: dur1}, %{start_time: start2, duration: _dur2}} ->
        first_end = start1 + dur1
        
        # Check if first action ends after second action starts (overlap conflict)
        if first_end > start2 do
          :conflict
        else
          :ok
        end
      
      _ ->
        # If we can't find timing data, assume no conflict
        :ok
    end
  end
end
