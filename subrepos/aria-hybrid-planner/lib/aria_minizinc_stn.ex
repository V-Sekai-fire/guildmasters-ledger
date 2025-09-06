# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincStn do
  @moduledoc """
  Matrix-based Simple Temporal Network (STN) solver using MiniZinc.

  This application provides mathematically correct STN constraint solving using
  a distance matrix representation with MiniZinc constraint satisfaction.

  ## STN Matrix Approach

  - **Distance Matrix**: Represents bounds on timepoint differences
  - **Proper STN Semantics**: Handles negative bounds and relative timing
  - **MiniZinc Backend**: Uses constraint satisfaction for consistency checking

  ## Usage

      # Basic STN solving with timepoint constraints
      stn = %{
        time_points: MapSet.new(["A", "B", "C"]),
        constraints: %{
          {"A", "B"} => {1, 5},    # B must be 1-5 units after A
          {"B", "C"} => {-2, 3}    # C can be 2 units before to 3 units after B
        },
        consistent: nil,
        metadata: %{}
      }
      {:ok, result} = AriaMinizincStn.solve_stn(stn)

      # Access solved timepoint values
      solved_times = result.metadata.solved_times
      # => %{"A" => 0, "B" => 3, "C" => 1}
  """

  require Logger

  # Configuration for dynamic bound calculation
  # Base multiplier for LOD-based bounds
  @default_bound_multiplier 1000
  # Safety limit to prevent numerical issues
  @max_reasonable_bound 1_000_000_000

  @type time_point :: String.t()
  @type constraint_bounds :: {number(), number()}
  @type stn_constraints :: %{optional({time_point(), time_point()}) => constraint_bounds()}
  @type stn :: %{
          time_points: MapSet.t(time_point()),
          constraints: stn_constraints(),
          consistent: boolean() | nil,
          metadata: map()
        }
  @type solver_options :: keyword()
  @type solution :: %{status: :satisfiable | :unsatisfiable, start_times: [number()]}
  @type error_reason :: String.t()

  @doc """
  Solve an STN using MiniZinc constraint solving.

  ## Parameters
  - `stn` - STN data structure with time_points, constraints, etc.
  - `options` - Solver options including :timeout

  ## Options
  - `:timeout` - Timeout in milliseconds (default: 30_000)

  ## Returns
  - `{:ok, updated_stn}` - Successfully solved STN with consistency info
  - `{:error, reason}` - Failed to solve STN

  ## Examples

      # Basic STN solving
      {:ok, result} = AriaMinizincStn.solve_stn(stn)
      result.consistent  # => true/false
  """
  @spec solve_stn(stn(), solver_options()) :: {:ok, stn()} | {:error, error_reason()}
  def solve_stn(stn, options \\ []) do
    with :ok <- validate_stn(stn) do
      solve_with_minizinc(stn, options)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Solve using MiniZinc constraint solver
  defp solve_with_minizinc(stn, options) do
    case convert_stn_to_minizinc(stn) do
      {:ok, template_vars} ->
        template_path = template_path()
        exec_options = [timeout: Keyword.get(options, :timeout, 30_000)]

        case AriaMinizincExecutor.exec(template_path, template_vars, exec_options) do
          {:ok, executor_result} ->
            # Try to parse the raw output first, then fall back to parsed solution
            raw_output = Map.get(executor_result, :raw_output, "")

            case parse_minizinc_output(raw_output, template_vars) do
              {:ok, %{status: :unsatisfiable}} ->
                # Return STN with consistent: false instead of error tuple
                updated_stn = update_stn_with_solution(stn, %{status: :unsatisfiable})

                {:ok,
                 %{updated_stn | metadata: Map.put(updated_stn.metadata, :solver, :minizinc)}}

              {:ok, solution} ->
                updated_stn = update_stn_with_solution(stn, solution)

                {:ok,
                 %{updated_stn | metadata: Map.put(updated_stn.metadata, :solver, :minizinc)}}

              {:error, _reason} ->
                # Fallback: try parsing the structured solution from executor
                case Map.get(executor_result, :solution) do
                  %{start_times: start_times} when is_list(start_times) ->
                    solution = %{status: :satisfiable, start_times: start_times}
                    updated_stn = update_stn_with_solution(stn, solution)

                    {:ok,
                     %{updated_stn | metadata: Map.put(updated_stn.metadata, :solver, :minizinc)}}

                  _ ->
                    {:error,
                     "Failed to parse MiniZinc output from both raw and structured formats"}
                end
            end

          {:error, reason} ->
            {:error, "MiniZinc execution failed: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Validate STN structure and constraint bounds
  defp validate_stn(stn) do
    cond do
      not is_map(stn) ->
        {:error, "STN must be a map"}

      not Map.has_key?(stn, :time_points) ->
        {:error, "STN must have :time_points field"}

      not Map.has_key?(stn, :constraints) ->
        {:error, "STN must have :constraints field"}

      not is_map(stn.constraints) ->
        {:error, "STN constraints must be a map"}

      true ->
        validate_constraint_bounds(stn.constraints)
    end
  end

  # Validate that all constraint values are within reasonable bounds
  defp validate_constraint_bounds(constraints) do
    invalid_constraint =
      Enum.find(constraints, fn {_key, {min_val, max_val}} ->
        exceeds_bound?(min_val) or exceeds_bound?(max_val)
      end)

    case invalid_constraint do
      nil ->
        :ok

      {{from, to}, {min_val, max_val}} ->
        {:error,
         "Constraint from #{from} to #{to} has values (#{min_val}, #{max_val}) exceeding maximum bound #{@max_reasonable_bound}"}
    end
  end

  # Check if a constraint value exceeds the reasonable bound
  defp exceeds_bound?(value) when is_number(value) do
    abs(value) > @max_reasonable_bound
  end

  # Infinity values are handled separately in matrix building
  defp exceeds_bound?(:infinity), do: false
  defp exceeds_bound?(:neg_infinity), do: false
  defp exceeds_bound?(:pos_infinity), do: false
  # Other non-numeric values are handled elsewhere
  defp exceeds_bound?(_), do: false

  # Convert STN data structure to MiniZinc template variables
  defp convert_stn_to_minizinc(stn) do
    time_points = MapSet.to_list(stn.time_points)

    if Enum.empty?(time_points) do
      {:error, "Empty STN - no time points to solve"}
    else
      time_point_map =
        time_points |> Enum.with_index(1) |> Map.new(fn {point, index} -> {point, index} end)

      %{lower_bounds: lower_bounds, upper_bounds: upper_bounds} =
        build_distance_matrix(stn.constraints, time_point_map, stn)

      # Calculate domain bounds based on actual constraint values
      {min_domain, max_domain} = calculate_domain_bounds(lower_bounds, upper_bounds)

      # Pre-generate the output format string to avoid mixing EEx and MiniZinc scoping
      output_pairs =
        time_points
        |> Enum.with_index(1)
        |> Enum.map(fn {name, index} -> "\"\\\"#{name}\\\": \" ++ show(timepoints[#{index}])" end)

      output_format = "join(\", \", [#{Enum.join(output_pairs, ", ")}])"

      template_vars = %{
        num_timepoints: length(time_points),
        lower_bounds: lower_bounds,
        upper_bounds: upper_bounds,
        min_domain: min_domain,
        max_domain: max_domain,
        timepoint_names: time_points,
        output_format: output_format,
        time_point_map: time_point_map
      }

      {:ok, template_vars}
    end
  end

  # Build STN distance matrix from constraints
  defp build_distance_matrix(constraint_map, time_point_map, stn) do
    num_points = map_size(time_point_map)

    # Calculate LOD-based bounds for unconstrained timepoint pairs
    {default_lower_bound, default_upper_bound} = calculate_no_constraint_bounds(stn)

    # Build flattened matrices as lists for template rendering
    lower_bounds =
      for i <- 1..num_points, j <- 1..num_points do
        if i == j do
          # Self-constraints are always 0
          0
        else
          # Find constraint between timepoints
          point_i = get_point_by_index(time_point_map, i)
          point_j = get_point_by_index(time_point_map, j)

          case Map.get(constraint_map, {point_i, point_j}) do
            {min_bound, _max_bound} when is_number(min_bound) -> round(min_bound)
            # Default unconstrained lower bound
            _ -> default_lower_bound
          end
        end
      end

    upper_bounds =
      for i <- 1..num_points, j <- 1..num_points do
        if i == j do
          # Self-constraints are always 0
          0
        else
          # Find constraint between timepoints
          point_i = get_point_by_index(time_point_map, i)
          point_j = get_point_by_index(time_point_map, j)

          case Map.get(constraint_map, {point_i, point_j}) do
            {_min_bound, max_bound} when is_number(max_bound) -> round(max_bound)
            # Default unconstrained upper bound
            _ -> default_upper_bound
          end
        end
      end

    %{lower_bounds: lower_bounds, upper_bounds: upper_bounds}
  end

  # Calculate LOD-based bounds for unconstrained timepoint pairs.
  # 
  # This replaces magical constants with bounds derived from the STN's
  # Level of Detail (LOD) and time unit settings.
  @spec calculate_no_constraint_bounds(map()) :: {integer(), integer()}
  defp calculate_no_constraint_bounds(stn) do
    # Extract LOD and time unit information with sensible defaults
    # Default to medium LOD
    lod_resolution = Map.get(stn, :lod_resolution, 100)
    # Default to seconds
    time_unit = Map.get(stn, :time_unit, :second)

    # Base bound calculation: larger LOD resolution = larger bounds
    # This reflects that coarser LOD levels need more permissive bounds
    base_bound = lod_resolution * @default_bound_multiplier

    # Scale by time unit - smaller units need larger numeric bounds
    # to represent the same real-world time spans
    scaled_bound =
      case time_unit do
        # Very fine granularity
        :microsecond -> base_bound * 1000
        # Fine granularity  
        :millisecond -> base_bound * 100
        # Base granularity
        :second -> base_bound
        # Coarser granularity
        :minute -> div(base_bound, 10)
        # Much coarser
        :hour -> div(base_bound, 100)
        # Very coarse
        :day -> div(base_bound, 1000)
        # Fallback for unknown units
        _ -> base_bound
      end

    # Apply safety limits to prevent numerical issues in MiniZinc
    final_bound = min(scaled_bound, @max_reasonable_bound)

    # Return symmetric bounds representing "no constraint"
    {-final_bound, final_bound}
  end

  defp get_point_by_index(time_point_map, index) do
    time_point_map
    |> Enum.find(fn {_point, idx} -> idx == index end)
    |> case do
      {point, _idx} -> point
      nil -> nil
    end
  end

  # Calculate appropriate domain bounds for MiniZinc variables based on constraint values
  defp calculate_domain_bounds(lower_bounds, upper_bounds) do
    all_bounds = lower_bounds ++ upper_bounds

    # Find the actual min and max values, excluding the default bounds
    # We exclude both old magical constants and new dynamic bounds that represent "no constraint"
    actual_bounds =
      Enum.reject(all_bounds, fn bound ->
        # Exclude dynamic bounds that are likely "no constraint" indicators
        # Exclude very large bounds as "no constraint" indicators
        bound == -1000 or bound == 1000 or bound == 0 or
          bound == -100_000_000 or bound == 100_000_000 or
          abs(bound) >= @max_reasonable_bound or
          abs(bound) >= 1_000_000
      end)

    {min_bound, max_bound} =
      case actual_bounds do
        [] ->
          # No actual constraints, use reasonable defaults
          {-10000, 10000}

        bounds ->
          min_val = Enum.min(bounds)
          max_val = Enum.max(bounds)

          # Add some buffer to handle constraint propagation
          buffer = max(abs(min_val), abs(max_val)) * 0.1 + 1000
          {round(min_val - buffer), round(max_val + buffer)}
      end

    # No internal domain limits - use the calculated bounds directly
    {min_bound, max_bound}
  end

  # Parse MiniZinc output (handles both string and structured responses)
  defp parse_minizinc_output(output, template_vars) when is_binary(output) do
    Logger.debug("Parsing MiniZinc output: #{inspect(output)}")

    cond do
      String.contains?(output, "=====UNSATISFIABLE=====") ->
        {:ok, %{status: :unsatisfiable}}

      true ->
        # Clean the output by removing the MiniZinc separator
        clean_output = output |> String.split("----------") |> List.first() |> String.trim()
        Logger.debug("Cleaned output for JSON parsing: #{inspect(clean_output)}")

        case Jason.decode(clean_output) do
          {:ok, %{"status" => "SATISFIABLE", "timepoints" => timepoints}} ->
            {:ok, %{status: :satisfiable, timepoints: timepoints}}

          {:ok, %{"status" => "SATISFIABLE", "start_times" => start_times}} ->
            # Backward compatibility with old format
            {:ok, %{status: :satisfiable, start_times: start_times}}

          {:ok, %{"status" => "UNSATISFIABLE"}} ->
            {:ok, %{status: :unsatisfiable}}

          {:ok, %{"timepoints" => timepoints}} when is_list(timepoints) ->
            # Handle raw timepoints array from MiniZinc JSON output
            Logger.debug("Found raw timepoints array: #{inspect(timepoints)}")
            timepoint_map = convert_timepoints_to_map(timepoints, template_vars)
            {:ok, %{status: :satisfiable, timepoints: timepoint_map}}

          {:ok, parsed} ->
            Logger.debug("Unmatched JSON parse result: #{inspect(parsed)}")
            {:error, "Invalid result format: #{inspect(parsed)}"}

          {:error, reason} ->
            {:error, "JSON decode failed: #{inspect(reason)}"}
        end
    end
  end

  defp parse_minizinc_output(output, template_vars) when is_map(output) do
    # Handle structured response from executor
    case output do
      %{raw_output: raw_output} when is_binary(raw_output) ->
        parse_minizinc_output(raw_output, template_vars)

      %{solution: solution} when is_map(solution) ->
        case Map.get(solution, :start_times) do
          start_times when is_list(start_times) ->
            {:ok, %{status: :satisfiable, start_times: start_times}}

          _ ->
            {:ok, %{status: :unsatisfiable}}
        end

      _ ->
        {:error, "Invalid structured output format: #{inspect(output)}"}
    end
  end

  defp parse_minizinc_output(output, _template_vars) do
    {:error, "Expected string or map output, got: #{inspect(output)}"}
  end

  # Convert raw timepoints array to named timepoint map
  defp convert_timepoints_to_map(timepoints, template_vars) do
    timepoint_names = Map.get(template_vars, :timepoint_names, [])

    Logger.debug(
      "Converting timepoints: #{inspect(timepoints)} with names: #{inspect(timepoint_names)}"
    )

    result =
      timepoint_names
      |> Enum.with_index()
      |> Enum.map(fn {name, index} ->
        value = Enum.at(timepoints, index, 0)
        Logger.debug("Mapping #{name} (index #{index}) to value #{value}")
        {name, value}
      end)
      |> Map.new()

    Logger.debug("Final timepoint map: #{inspect(result)}")
    result
  end

  defp update_stn_with_solution(stn, solution) do
    consistent = solution.status == :satisfiable
    updated_stn = %{stn | consistent: consistent}

    if consistent do
      solved_times =
        cond do
          # New timepoint format
          solution[:timepoints] -> solution[:timepoints]
          # Legacy format
          solution[:start_times] -> extract_solved_times(stn, solution)
          true -> %{}
        end

      %{updated_stn | metadata: Map.put(updated_stn.metadata, :solved_times, solved_times)}
    else
      # For unsatisfiable cases, provide empty solved_times to prevent nil access
      %{updated_stn | metadata: Map.put(updated_stn.metadata, :solved_times, %{})}
    end
  end

  defp extract_solved_times(stn, solution) do
    time_points = MapSet.to_list(stn.time_points)
    start_times = solution[:start_times] || []

    time_point_map =
      time_points |> Enum.with_index(1) |> Map.new(fn {point, index} -> {point, index} end)

    index_to_point_map =
      time_point_map |> Enum.map(fn {point, index} -> {index, point} end) |> Map.new()

    start_times
    |> Enum.with_index(1)
    |> Enum.map(fn {start_time, index} ->
      case Map.get(index_to_point_map, index) do
        nil -> nil
        time_point -> {time_point, start_time}
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  # Get template path
  defp template_path do
    Path.join([
      Application.app_dir(:aria_hybrid_planner),
      "priv",
      "templates",
      "stn_temporal.mzn.eex"
    ])
  end
end
