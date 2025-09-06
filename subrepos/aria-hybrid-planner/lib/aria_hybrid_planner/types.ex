defmodule AriaHybridPlanner.Types do
  @moduledoc """
  Core type definitions for AriaHybridPlanner.

  This module contains all the type specifications used throughout the
  AriaHybridPlanner application, providing comprehensive type safety
  for domain management, state handling, temporal constraints, and planning.
  """

  # ============================================================================
  # Basic Types
  # ============================================================================

  @type predicate :: String.t() | atom()
  @type subject :: String.t() | atom()
  @type fact_value :: term()
  @type fact :: {predicate(), subject(), fact_value()}

  # ============================================================================
  # State Types
  # ============================================================================

  @type state :: AriaState.t()
  @type state_error :: {:error, String.t()}

  # ============================================================================
  # Domain Types
  # ============================================================================

  @type domain_name :: atom() | String.t()
  @type method_name :: atom() | String.t()
  @type action_name :: atom() | String.t()

  @type domain :: %{
    name: domain_name(),
    actions: %{action_name() => action_spec()},
    methods: %{
      task: %{method_name() => task_method_spec()},
      unigoal: %{method_name() => unigoal_method_spec()},
      multigoal: [multigoal_method_spec()],
      multitodo: [multitodo_method_spec()]
    },
    entity_registry: entity_registry(),
    temporal_specifications: temporal_specifications(),
    type: :domain | :legacy
  }

  @type action_spec :: %{
    action_fn: (state(), list() -> {:ok, state()} | state_error()),
    metadata: action_metadata(),
    duration: duration_spec() | nil,
    entity_requirements: [entity_requirement()] | nil
  }

  @type action_metadata :: %{
    optional(:description) => String.t(),
    optional(:category) => atom(),
    optional(:priority) => integer(),
    optional(any()) => any()
  }

  @type task_method_spec :: %{
    name: method_name(),
    decomposition_fn: (state(), list() -> [plan_step()]),
    metadata: method_metadata()
  }

  @type unigoal_method_spec :: %{
    name: method_name(),
    goal_pattern: goal_pattern(),
    decomposition_fn: (state(), goal() -> [plan_step()]),
    metadata: method_metadata()
  }

  @type multigoal_method_spec :: %{
    name: method_name(),
    decomposition_fn: (state(), [goal()] -> [plan_step()]),
    metadata: method_metadata()
  }

  @type multitodo_method_spec :: %{
    name: method_name(),
    decomposition_fn: (state(), [todo_item()] -> [plan_step()]),
    metadata: method_metadata()
  }

  @type method_metadata :: %{
    optional(:description) => String.t(),
    optional(:applicable_when) => (state() -> boolean()),
    optional(any()) => any()
  }

  # ============================================================================
  # Planning Types
  # ============================================================================

  @type todo_item :: goal() | task() | multigoal()
  @type goal :: {predicate(), subject(), fact_value()}
  @type task :: {:task, method_name(), list()}
  @type multigoal :: AriaEngineCore.Multigoal.t()

  @type plan_step :: goal() | task() | {:action, action_name(), list()}
  @type plan_result :: {:ok, plan()} | {:error, String.t()}

  @type plan :: %{
    solution_tree: solution_tree(),
    statistics: plan_statistics(),
    metadata: plan_metadata()
  }

  @type solution_tree :: %{
    root_id: node_id(),
    nodes: %{node_id() => solution_node()},
    blacklisted_commands: MapSet.t(),
    goal_network: goal_network()
  }

  @type node_id :: String.t()
  @type solution_node :: %{
    id: node_id(),
    task: plan_step(),
    parent_id: node_id() | nil,
    children_ids: [node_id()],
    state: state(),
    visited: boolean(),
    expanded: boolean(),
    method_tried: method_name() | nil,
    blacklisted_methods: [method_name()],
    is_primitive: boolean(),
    is_durative: boolean()
  }

  @type plan_statistics :: %{
    total_nodes: non_neg_integer(),
    primitive_actions: non_neg_integer(),
    task_nodes: non_neg_integer(),
    execution_time: non_neg_integer(),
    search_depth: non_neg_integer()
  }

  @type plan_metadata :: %{
    optional(:algorithm) => atom(),
    optional(:timestamp) => DateTime.t(),
    optional(:version) => String.t(),
    optional(any()) => any()
  }

  @type goal_network :: %{goal() => [node_id()]}

  # ============================================================================
  # Entity Types
  # ============================================================================

  @type entity_registry :: %{
    entities: %{entity_id() => entity()},
    types: %{entity_type() => entity_type_spec()},
    allocations: %{allocation_id() => allocation()}
  }

  @type entity_id :: String.t() | atom()
  @type entity_type :: atom()
  @type capability :: atom()

  @type entity :: %{
    id: entity_id(),
    type: entity_type(),
    capabilities: [capability()],
    properties: %{atom() => term()},
    available: boolean(),
    allocated_to: allocation_id() | nil
  }

  @type entity_type_spec :: %{
    capabilities: [capability()],
    properties_schema: %{atom() => atom()},
    max_instances: non_neg_integer() | :unlimited
  }

  @type entity_requirement :: %{
    type: entity_type(),
    capabilities: [capability()],
    properties: %{atom() => term()},
    count: pos_integer()
  }

  @type allocation_id :: String.t()
  @type allocation :: %{
    id: allocation_id(),
    entity_ids: [entity_id()],
    action_id: action_id(),
    timestamp: DateTime.t()
  }

  @type action_id :: String.t()

  # ============================================================================
  # Temporal Types
  # ============================================================================

  @type temporal_specifications :: %{
    actions: %{action_name() => action_temporal_spec()},
    constraints: [temporal_constraint()],
    time_unit: time_unit()
  }

  @type action_temporal_spec :: %{
    duration: duration_spec(),
    constraints: [temporal_constraint()],
    execution_pattern: execution_pattern()
  }

  @type duration_spec :: fixed_duration() | variable_duration() | conditional_duration()

  @type fixed_duration :: %{
    type: :fixed,
    value: non_neg_integer(),
    unit: time_unit()
  }

  @type variable_duration :: %{
    type: :variable,
    min: non_neg_integer(),
    max: non_neg_integer(),
    unit: time_unit()
  }

  @type conditional_duration :: %{
    type: :conditional,
    conditions: [%{condition: (state() -> boolean()), duration: duration_spec()}],
    default: duration_spec()
  }

  @type temporal_constraint :: %{
    type: :before | :after | :during | :meets | :overlaps,
    from_action: action_name(),
    to_action: action_name(),
    offset: integer(),
    unit: time_unit()
  }

  @type execution_pattern :: :sequential | :parallel | :conditional
  @type time_unit :: :microsecond | :millisecond | :second | :minute | :hour | :day

  # ============================================================================
  # Goal Pattern Types
  # ============================================================================

  @type goal_pattern :: {predicate(), subject(), fact_value()} | :any

  # ============================================================================
  # Error Types
  # ============================================================================

  @type planning_error :: {:error, planning_error_reason()}
  @type planning_error_reason ::
    :no_solution_found |
    :inconsistent_constraints |
    :resource_unavailable |
    :timeout |
    :invalid_domain |
    :invalid_state |
    String.t()

  @type validation_error :: {:error, validation_error_reason()}
  @type validation_error_reason ::
    :missing_required_fields |
    :invalid_type |
    :constraint_violation |
    :circular_dependency |
    String.t()

  # ============================================================================
  # Execution Types
  # ============================================================================

  @type execution_result :: {:ok, execution_success()} | {:error, execution_error()}
  @type execution_success :: {solution_tree(), state()}
  @type execution_error :: String.t()

  @type lazy_execution_result :: {:ok, state()} | {:error, String.t()}

  # ============================================================================
  # Configuration Types
  # ============================================================================

  @type planner_config :: %{
    optional(:algorithm) => :dfs | :bfs | :astar,
    optional(:max_depth) => non_neg_integer(),
    optional(:timeout) => non_neg_integer(),
    optional(:verbose) => 0..3,
    optional(:enable_solution_tree) => boolean(),
    optional(:verify_goals) => boolean()
  }

  # ============================================================================
  # Utility Type Guards
  # ============================================================================

  defguard is_valid_predicate(pred) when is_binary(pred) or is_atom(pred)
  defguard is_valid_subject(subj) when is_binary(subj) or is_atom(subj)
  defguard is_valid_fact_value(value) when not is_nil(value)

  defguard is_valid_goal(goal)
           when is_tuple(goal) and tuple_size(goal) == 3 and
                is_valid_predicate(elem(goal, 0)) and
                is_valid_subject(elem(goal, 1)) and
                is_valid_fact_value(elem(goal, 2))

  defguard is_valid_duration(duration)
           when is_integer(duration) and duration >= 0

  defguard is_valid_time_unit(unit)
           when unit in [:microsecond, :millisecond, :second, :minute, :hour, :day]
end
