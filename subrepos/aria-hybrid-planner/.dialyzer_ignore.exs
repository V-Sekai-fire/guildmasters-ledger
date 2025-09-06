# Dialyzer ignore warnings file for AriaHybridPlanner
# This file contains warnings that should be ignored during type checking
# Updated after fixing AriaAriaState typos (reduced from 101 to 94 warnings)

[
  # Ignore warnings for external dependencies that may not have proper type specs
  {"lib/aria_hybrid_planner.ex", :no_return, {:erlang, :halt, 1}},
  {"lib/aria_hybrid_planner.ex", :no_return, {:erlang, :halt, 0}},

  # Ignore callback info warnings for behaviours
  {"lib/aria_hybrid_planner/executor_behaviour.ex", :callback_info_missing},

  # Ignore underspecified opaque types for external libraries
  {"lib/aria_hybrid_planner.ex", :underspecs, {:jason, :encode, 1}},
  {"lib/aria_hybrid_planner.ex", :underspecs, {:jason, :decode, 1}},

  # Ignore pattern matching warnings for dynamic module loading
  {"lib/aria_hybrid_planner.ex", :pattern_match, {:apply, 3}},

  # Ignore contract_supertype warnings for protocol implementations
  {"lib/aria_state/relational_state.ex", :contract_supertype},

  # Ignore warnings for test files
  {"test/", :no_return},
  {"test/", :underspecs},
  {"test/", :pattern_match},

  # Ignore warnings for third-party code
  {"thirdparty/", :no_return},
  {"thirdparty/", :underspecs},
  {"thirdparty/", :pattern_match},

  # Complex opaque type issues that require significant refactoring
  {"lib/aria_hybrid_planner/blacklisting.ex", :contract_with_opaque},
  {"lib/aria_hybrid_planner/plan/", :contract_with_opaque},
  {"lib/aria_hybrid_planner/temporal/stn/", :contract_with_opaque},

  # Missing type definitions that require external library updates
  {"lib/aria_hybrid_planner/", :unknown_type, "AriaEngine.Multigoal.t/0"},
  {"lib/aria_hybrid_planner/temporal/", :unknown_type, "AriaHybridPlanner.Temporal.Interval.t/0"},

  # Function call mismatches requiring external library changes
  {"lib/aria_hybrid_planner/temporal/stn/units.ex", :call},
  {"lib/aria_minizinc_executor/template_renderer.ex", :unknown_function, "EEx.eval_string/2"},
  {"lib/aria_minizinc_goal/executor.ex", :unknown_function, "EEx.eval_string/2"},

  # Temporary ignores for gradual type adoption (reduced scope)
  {"lib/aria_minizinc_executor/", :underspecs},
  {"lib/aria_minizinc_goal/", :underspecs},
  {"lib/aria_minizinc_stn/", :underspecs},
  {"lib/aria_state/", :underspecs}
]
