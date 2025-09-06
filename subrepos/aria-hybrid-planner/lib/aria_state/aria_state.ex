# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState do
  @moduledoc """
  State management for AriaEngine planning systems.

  Predicate-centric state management using predicate-subject-fact triples.
  Each fact is represented as {predicate, subject} -> fact_value.

  ## Public API (Domain Developers)

  ```elixir
  # Predicate-centric, pipe-friendly API
  state = AriaState.new()
  |> AriaState.set_fact("status", "chef_1", "cooking")
  |> AriaState.set_fact("status", "meal_001", "in_progress")
  |> AriaState.set_fact("temperature", "oven_1", 375)

  # Reading facts
  chef_status = AriaState.get_fact(state, "status", "chef_1")
  # => {:ok, "cooking"}
  ```

  ## Internal API (AriaEngine)

  AriaState.RelationalState is used internally for performance-optimized queries.

  ## Conversion Between Formats

  ```elixir
  # Convert AriaState to RelationalState
  relational_state = AriaState.convert(state)

  # Convert RelationalState to AriaState
  state = AriaState.convert(relational_state)
  ```
  """

  @type subject :: String.t()
  @type predicate :: String.t()
  @type fact_value :: any()
  @type entity_key :: {predicate(), subject()}
  @type t :: %__MODULE__{data: %{entity_key() => fact_value()}}

  defstruct data: %{}

  @doc "Creates a new empty state."
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc "Creates a new state from a map of predicate-subject-object data."
  @spec new(map()) :: t()
  def new(data) when is_map(data) do
    # Check if data is already in entity format {predicate, subject} => value
    if is_entity_format?(data) do
      %__MODULE__{data: data}
    else
      # Convert nested predicate maps to entity format
      converted_data = convert_nested_maps_to_entities(data)
      %__MODULE__{data: converted_data}
    end
  end

  # Check if the data is already in entity format
  defp is_entity_format?(data) do
    data
    |> Map.keys()
    |> Enum.all?(fn
      {predicate, subject} when is_binary(predicate) and is_binary(subject) -> true
      _ -> false
    end)
  end

  # Convert nested predicate maps to entity format
  defp convert_nested_maps_to_entities(data) do
    data
    |> Enum.flat_map(fn
      {predicate, subject_map} when is_map(subject_map) ->
        predicate_str = to_string(predicate)

        Enum.map(subject_map, fn {subject, value} ->
          {{predicate_str, to_string(subject)}, value}
        end)

      {key, value} ->
        # Handle direct key-value pairs (already in some entity-like format)
        [{key, value}]
    end)
    |> Map.new()
  end

  @doc """
  Gets a specific fact from the state.

  ## Parameters

  - `state`: The state
  - `predicate`: The predicate to look up
  - `subject`: The subject (entity) to look up

  ## Returns

  `{:ok, value}` if found, `{:error, :not_found}` if not found.

  ## Examples

      iex> state = AriaState.new()
      iex> state = AriaState.set_fact(state, "location", "player", "room1")
      iex> AriaState.get_fact(state, "location", "player")
      {:ok, "room1"}
  """
  @spec get_fact(t(), predicate(), subject()) :: {:ok, fact_value()} | {:error, :not_found}
  def get_fact(%__MODULE__{data: data}, predicate, subject) do
    case Map.get(data, {predicate, subject}) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  @doc """
  Sets a fact in the state.

  ## Parameters

  - `state`: The state
  - `predicate`: The predicate to set
  - `subject`: The subject (entity) to set
  - `value`: The value to set

  ## Returns

  Updated state with the fact set.

  ## Examples

      iex> state = AriaState.new()
      iex> state = AriaState.set_fact(state, "location", "player", "room1")
      iex> AriaState.get_fact(state, "location", "player")
      {:ok, "room1"}
  """
  @spec set_fact(t(), predicate(), subject(), fact_value()) :: t()
  def set_fact(%__MODULE__{data: data}, predicate, subject, value) do
    %__MODULE__{data: Map.put(data, {predicate, subject}, value)}
  end

  @doc "Removes a fact from the state."
  @spec remove_fact(t(), predicate(), subject()) :: t()
  def remove_fact(%__MODULE__{data: data}, predicate, subject) do
    %__MODULE__{data: Map.delete(data, {predicate, subject})}
  end

  @doc "Checks if a predicate variable exists in any subject."
  @spec has_predicate_variable?(t(), predicate()) :: boolean()
  def has_predicate_variable?(%__MODULE__{data: data}, predicate) do
    data |> Map.keys() |> Enum.any?(fn {pred, _subject} -> pred == predicate end)
  end

  @doc "Checks if a specific predicate exists for a given subject."
  @spec has_predicate?(t(), predicate(), subject()) :: boolean()
  def has_predicate?(%__MODULE__{data: data}, predicate, subject) do
    Map.has_key?(data, {predicate, subject})
  end

  @doc "Gets a list of all subjects that have properties."
  @spec get_subjects(t()) :: [subject()]
  def get_subjects(%__MODULE__{data: data}) do
    data |> Map.keys() |> Enum.map(fn {_predicate, subject} -> subject end) |> Enum.uniq()
  end

  @doc "Gets all predicates for a given subject."
  @spec get_subject_properties(t(), subject()) :: [predicate()]
  def get_subject_properties(%__MODULE__{data: data}, subject) do
    data
    |> Map.keys()
    |> Enum.filter(fn {_predicate, subj} -> subj == subject end)
    |> Enum.map(fn {predicate, _subj} -> predicate end)
  end

  @doc "Gets all triples as a list of {predicate, subject, fact_value} tuples."
  @spec to_triples(t()) :: [{predicate(), subject(), fact_value()}]
  def to_triples(%__MODULE__{data: data}) do
    Enum.map(data, fn {{predicate, subject}, fact_value} -> {predicate, subject, fact_value} end)
  end

  @doc "Gets all facts in the state as a map."
  @spec get_all_facts(t()) :: %{entity_key() => fact_value()}
  def get_all_facts(%__MODULE__{data: data}) do
    data
  end

  @doc """
  Gets all subjects that have a specific predicate with a specific fact_value.

  Example:
  ```elixir
  # Get all subjects with status "available"
  AriaState.get_subjects_with_fact(state, "status", "available")
  # => ["chef1", "chef3", "table2"]
  ```
  """
  @spec get_subjects_with_fact(t(), predicate(), fact_value()) :: [subject()]
  def get_subjects_with_fact(%__MODULE__{data: data}, predicate, fact_value) do
    data
    |> Enum.filter(fn {{pred, _subj}, val} -> pred == predicate and val == fact_value end)
    |> Enum.map(fn {{_pred, subj}, _val} -> subj end)
  end

  @doc """
  Gets all subjects that match a predicate pattern, regardless of fact_value.

  Example:
  ```elixir
  # Get all subjects that have a "location" predicate
  AriaState.get_subjects_with_predicate(state, "location")
  # => ["player", "npc1", "chest"]
  ```
  """
  @spec get_subjects_with_predicate(t(), predicate()) :: [subject()]
  def get_subjects_with_predicate(%__MODULE__{data: data}, predicate) do
    data
    |> Map.keys()
    |> Enum.filter(fn {pred, _subj} -> pred == predicate end)
    |> Enum.map(fn {_pred, subj} -> subj end)
    |> Enum.uniq()
  end

  @doc """
  Checks if the state matches a specific predicate, subject, and fact_value pattern.

  This function is used by the planner to check if a goal condition is satisfied
  in the current state. It returns true if the state contains the specified triple.
  """
  @spec matches?(t(), predicate(), subject(), fact_value()) :: boolean()
  def matches?(%__MODULE__{data: data}, predicate, subject, fact_value) do
    case Map.get(data, {predicate, subject}) do
      ^fact_value -> true
      _ -> false
    end
  end

  @doc """
  Evaluates existential quantifier: checks if there exists at least one subject
  that matches the given predicate and fact_value pattern.

  Example:
  ```elixir
  # Check if there exists any chair that is available
  AriaState.exists?(state, "status", "available", &String.contains?(&1, "chair"))
  ```
  """
  @spec exists?(t(), predicate(), fact_value()) :: boolean()
  def exists?(state, predicate, fact_value), do: exists?(state, predicate, fact_value, nil)

  @spec exists?(t(), predicate(), fact_value(), (subject() -> boolean()) | nil) :: boolean()
  def exists?(%__MODULE__{data: data}, predicate, fact_value, subject_filter) do
    data
    |> Enum.any?(fn
      {{^predicate, subject}, ^fact_value} ->
        case subject_filter do
          nil -> true
          filter_fn when is_function(filter_fn, 1) -> filter_fn.(subject)
          _ -> false
        end

      _ ->
        false
    end)
  end

  @doc """
  Evaluates universal quantifier: checks if all subjects matching the pattern
  have the specified predicate and fact_value.

  Example:
  ```elixir
  # Check if all doors are locked
  AriaState.forall?(state, "status", "locked", &String.contains?(&1, "door"))
  ```
  """
  @spec forall?(t(), predicate(), fact_value(), (subject() -> boolean())) :: boolean()
  def forall?(%__MODULE__{data: data}, predicate, fact_value, subject_filter)
      when is_function(subject_filter, 1) do
    matching_subjects =
      data
      |> Map.keys()
      |> Enum.map(fn {_pred, subj} -> subj end)
      |> Enum.uniq()
      |> Enum.filter(subject_filter)

    if Enum.empty?(matching_subjects) do
      true
    else
      Enum.all?(matching_subjects, fn subject ->
        matches?(%__MODULE__{data: data}, predicate, subject, fact_value)
      end)
    end
  end

  @doc """
  Evaluates a condition structure.

  Supports existential and universal quantifiers, logical operators, comparison operators,
  and simple equality conditions.

  ## Condition Format
  ```elixir
  # Existential quantifier
  {:exists, subject_filter, predicate, fact_value}

  # Universal quantifier
  {:forall, subject_filter, predicate, fact_value}

  # Logical operators
  {:and, [condition1, condition2, ...]}
  {:or, [condition1, condition2, ...]}
  {:not, condition}

  # Comparison operators
  {:equals, predicate, subject, value}
  {:greater_than, predicate, subject, value}
  {:less_than, predicate, subject, value}
  {:greater_equal, predicate, subject, value}
  {:less_equal, predicate, subject, value}

  # Regular condition (backward compatibility)
  {predicate, subject, fact_value}
  ```

  ## Examples
  ```elixir
  # Check if any chair is available
  condition = {:exists, &String.contains?(&1, "chair"), "status", "available"}
  AriaState.evaluate_condition(state, condition)

  # Check if all doors are locked
  condition = {:forall, &String.contains?(&1, "door"), "status", "locked"}
  AriaState.evaluate_condition(state, condition)

  # Complex logical condition
  condition = {:and, [
    {:equals, "status", "chef_1", "available"},
    {:greater_than, "temperature", "oven_1", 300}
  ]}
  AriaState.evaluate_condition(state, condition)

  # Regular condition check
  condition = {"location", "player", "room1"}
  AriaState.evaluate_condition(state, condition)
  ```
  """
  @spec evaluate_condition(t(), tuple()) :: boolean()
  def evaluate_condition(state, condition)

  # Existential and universal quantifiers
  def evaluate_condition(state, {:exists, subject_filter, predicate, fact_value}) do
    exists?(state, predicate, fact_value, subject_filter)
  end

  def evaluate_condition(state, {:forall, subject_filter, predicate, fact_value}) do
    forall?(state, predicate, fact_value, subject_filter)
  end

  # Logical operators
  def evaluate_condition(state, {:and, conditions}) when is_list(conditions) do
    Enum.all?(conditions, &evaluate_condition(state, &1))
  end

  def evaluate_condition(state, {:or, conditions}) when is_list(conditions) do
    Enum.any?(conditions, &evaluate_condition(state, &1))
  end

  def evaluate_condition(state, {:not, condition}) do
    not evaluate_condition(state, condition)
  end

  # Comparison operators
  def evaluate_condition(state, {:equals, predicate, subject, value}) do
    matches?(state, predicate, subject, value)
  end

  def evaluate_condition(state, {:greater_than, predicate, subject, value}) do
    case get_fact(state, predicate, subject) do
      {:ok, actual_value} when is_number(actual_value) and is_number(value) ->
        actual_value > value

      _ ->
        false
    end
  end

  def evaluate_condition(state, {:less_than, predicate, subject, value}) do
    case get_fact(state, predicate, subject) do
      {:ok, actual_value} when is_number(actual_value) and is_number(value) ->
        actual_value < value

      _ ->
        false
    end
  end

  def evaluate_condition(state, {:greater_equal, predicate, subject, value}) do
    case get_fact(state, predicate, subject) do
      {:ok, actual_value} when is_number(actual_value) and is_number(value) ->
        actual_value >= value

      _ ->
        false
    end
  end

  def evaluate_condition(state, {:less_equal, predicate, subject, value}) do
    case get_fact(state, predicate, subject) do
      {:ok, actual_value} when is_number(actual_value) and is_number(value) ->
        actual_value <= value

      _ ->
        false
    end
  end

  # Simple equality condition (backward compatibility)
  def evaluate_condition(state, {predicate, subject, fact_value}) do
    matches?(state, predicate, subject, fact_value)
  end

  def evaluate_condition(_state, condition) do
    if Mix.env() == :dev or (Mix.env() == :test and ExUnit.configuration()[:trace]) do
      require Logger
      Logger.warning("Unknown condition format: #{inspect(condition)}")
    end

    false
  end

  @doc "Creates a state from a list of triples."
  @spec from_triples([{predicate(), subject(), fact_value()}]) :: t()
  def from_triples(triples) do
    data =
      triples
      |> Enum.map(fn {predicate, subject, fact_value} -> {{predicate, subject}, fact_value} end)
      |> Map.new()

    %__MODULE__{data: data}
  end

  @doc "Merges two states, with the second state taking precedence for conflicts."
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{data: data1}, %__MODULE__{data: data2}) do
    %__MODULE__{data: Map.merge(data1, data2)}
  end

  @doc "Returns a copy of the state with modified data."
  @spec copy(t()) :: t()
  def copy(%__MODULE__{data: data}) do
    %__MODULE__{data: Map.new(data)}
  end

  @doc "Checks if a specific predicate exists for a given subject."
  def has_subject?(%__MODULE__{} = state, predicate, subject) do
    has_predicate?(state, predicate, subject)
  end

  @doc "Checks if a goal is satisfied by the current state."
  def satisfies_goal?(%__MODULE__{} = state, goal) do
    case goal do
      {predicate, subject, value} ->
        matches?(state, predicate, subject, value)

      _ ->
        false
    end
  end

  @doc """
  Converts between AriaState and AriaState.RelationalState.

  ## Examples

  ```elixir
  # AriaState to RelationalState
  state = AriaState.new()
  |> AriaState.set_fact("status", "chef_1", "cooking")

  relational_state = AriaState.convert(state)
  # => %AriaState.RelationalState{...}

  # RelationalState to AriaState
  converted_back = AriaState.convert(relational_state)
  # => %AriaState{...}
  ```
  """
  @spec convert(t() | AriaState.RelationalState.t()) :: AriaState.RelationalState.t() | t()
  def convert(%__MODULE__{} = state) do
    # Data is already in {predicate, subject} => value format
    %AriaState.RelationalState{data: state.data}
  end

  def convert(%AriaState.RelationalState{} = relational_state) do
    # Data is already in {predicate, subject} => value format
    %__MODULE__{data: relational_state.data}
  end
end
