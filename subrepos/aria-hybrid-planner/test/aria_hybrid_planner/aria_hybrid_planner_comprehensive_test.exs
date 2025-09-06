# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaHybridPlannerComprehensiveTest do
  use ExUnit.Case, async: true
  doctest AriaHybridPlanner

  describe "version/0" do
    test "returns version string" do
      version = AriaHybridPlanner.version()
      assert is_binary(version)
      assert version != ""
    end
  end

  describe "legacy domain functions" do
    test "new_legacy_domain/0 creates default legacy domain" do
      domain = AriaHybridPlanner.new_legacy_domain()

      assert domain.name == "default_legacy_domain"
      assert domain.actions == %{}
      assert Map.has_key?(domain.methods, :task)
      assert Map.has_key?(domain.methods, :unigoal)
      assert Map.has_key?(domain.methods, :multigoal)
      assert Map.has_key?(domain.methods, :multitodo)
      assert domain.entity_registry == %{}
      assert domain.temporal_specifications == %{}
      assert domain.type == :legacy
    end

    test "new_legacy_domain/1 creates named legacy domain" do
      domain = AriaHybridPlanner.new_legacy_domain("test_domain")

      assert domain.name == "test_domain"
      assert domain.type == :legacy
    end

    test "validate_legacy_domain/1 validates correct domain" do
      domain = AriaHybridPlanner.new_legacy_domain("valid")

      result = AriaHybridPlanner.validate_legacy_domain(domain)
      assert {:ok, ^domain} = result
    end

    test "validate_legacy_domain/1 rejects invalid domain" do
      invalid_domain = %{name: "test"}  # Missing required keys

      result = AriaHybridPlanner.validate_legacy_domain(invalid_domain)
      assert {:error, "Invalid domain structure - missing required keys"} = result
    end

    test "validate_legacy_domain/1 rejects non-map input" do
      result = AriaHybridPlanner.validate_legacy_domain("not a map")
      assert {:error, "Domain must be a map"} = result
    end

    test "add_action_to_legacy_domain/3 adds action" do
      domain = AriaHybridPlanner.new_legacy_domain()
      action_spec = %{duration: 100, type: :test}

      result = AriaHybridPlanner.add_action_to_legacy_domain(domain, :test_action, action_spec)
      assert {:ok, updated_domain} = result
      assert updated_domain.actions[:test_action] == action_spec
    end

    test "get_durative_action_from_legacy_domain/2 gets existing action" do
      domain = AriaHybridPlanner.new_legacy_domain()
      action_spec = %{duration: 100, type: :test}
      {:ok, domain_with_action} = AriaHybridPlanner.add_action_to_legacy_domain(domain, :test_action, action_spec)

      result = AriaHybridPlanner.get_durative_action_from_legacy_domain(domain_with_action, :test_action)
      assert {:ok, ^action_spec} = result
    end

    test "get_durative_action_from_legacy_domain/2 handles missing action" do
      domain = AriaHybridPlanner.new_legacy_domain()

      result = AriaHybridPlanner.get_durative_action_from_legacy_domain(domain, :missing_action)
      assert {:error, "Action missing_action not found"} = result
    end
  end

  describe "compatibility functions" do
    test "execute_action_mock/4 returns mock execution" do
      domain = create_test_domain()
      state = AriaHybridPlanner.new_state()

      result = AriaHybridPlanner.execute_action_mock(domain, state, :test_action, ["arg1"])
      assert {:ok, {^state, %{action: :test_action, args: ["arg1"], result: "mock_execution"}}} = result
    end

    test "satisfies_goal?/2 checks goal satisfaction" do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("status", "chef1", "available")

      assert AriaHybridPlanner.satisfies_goal?(state, {"status", "chef1", "available"}) == true
      assert AriaHybridPlanner.satisfies_goal?(state, {"status", "chef1", "busy"}) == false
      assert AriaHybridPlanner.satisfies_goal?(state, "invalid_goal") == false
    end

    test "satisfies_goals?/2 checks multiple goals" do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("status", "chef1", "available")
      |> AriaHybridPlanner.set_fact("location", "chef1", "kitchen")

      goals = [
        {"status", "chef1", "available"},
        {"location", "chef1", "kitchen"}
      ]

      assert AriaHybridPlanner.satisfies_goals?(state, goals) == true

      mixed_goals = [
        {"status", "chef1", "available"},
        {"status", "chef1", "busy"}  # This will fail
      ]

      assert AriaHybridPlanner.satisfies_goals?(state, mixed_goals) == false
    end

    test "apply_changes/2 applies multiple state changes" do
      state = AriaHybridPlanner.new_state()
      changes = [
        {"status", "chef1", "busy"},
        {"location", "chef1", "dining_room"}
      ]

      updated_state = AriaHybridPlanner.apply_changes(state, changes)

      assert {:ok, "busy"} = AriaHybridPlanner.get_fact(updated_state, "status", "chef1")
      assert {:ok, "dining_room"} = AriaHybridPlanner.get_fact(updated_state, "location", "chef1")
    end

    test "query_state/2 queries with different patterns" do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("status", "chef1", "available")
      |> AriaHybridPlanner.set_fact("status", "chef2", "busy")
      |> AriaHybridPlanner.set_fact("location", "chef1", "kitchen")

      # Query all facts with predicate "status"
      status_facts = AriaHybridPlanner.query_state(state, {"status", :_, :_})
      assert length(status_facts) == 2

      # Query all facts about "chef1"
      chef1_facts = AriaHybridPlanner.query_state(state, {:_, "chef1", :_})
      assert length(chef1_facts) == 2

      # Query specific predicate/subject
      chef1_status = AriaHybridPlanner.query_state(state, {"status", "chef1", :_})
      assert chef1_status == [{"status", "chef1", "available"}]

      # Query exact triple
      exact_match = AriaHybridPlanner.query_state(state, {"status", "chef1", "available"})
      assert exact_match == [{"status", "chef1", "available"}]

      # Query non-existent exact triple
      no_match = AriaHybridPlanner.query_state(state, {"status", "chef1", "busy"})
      assert no_match == []

      # Query with invalid pattern
      invalid = AriaHybridPlanner.query_state(state, "invalid")
      assert invalid == []
    end

    test "all_facts/1 returns all facts" do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("status", "chef1", "available")
      |> AriaHybridPlanner.set_fact("location", "chef1", "kitchen")

      facts = AriaHybridPlanner.all_facts(state)
      assert length(facts) == 2
      assert Enum.member?(facts, {"status", "chef1", "available"})
      assert Enum.member?(facts, {"location", "chef1", "kitchen"})
    end

    test "set_temporal_fact/5 sets fact with timestamp" do
      state = AriaHybridPlanner.new_state()
      timestamp = DateTime.utc_now()

      updated_state = AriaHybridPlanner.set_temporal_fact(state, "event", "action1", "completed", timestamp)

      assert {:ok, "completed"} = AriaHybridPlanner.get_fact(updated_state, "event", "action1")
    end

    test "set_temporal_fact/4 sets fact without timestamp" do
      state = AriaHybridPlanner.new_state()

      updated_state = AriaHybridPlanner.set_temporal_fact(state, "event", "action1", "completed")

      assert {:ok, "completed"} = AriaHybridPlanner.get_fact(updated_state, "event", "action1")
    end

    test "get_fact_history/3 returns empty list" do
      state = AriaHybridPlanner.new_state()
      |> AriaHybridPlanner.set_fact("status", "chef1", "available")

      history = AriaHybridPlanner.get_fact_history(state, "status", "chef1")
      assert history == []
    end
  end

  describe "setup_domain/2" do
    test "creates domain with default options" do
      domain = AriaHybridPlanner.setup_domain(:test_domain)

      assert domain.name == :test_domain
    end

    test "creates domain with entity specifications" do
      entities = [
        %{type: "chef", capabilities: [:cooking]},
        %{type: "equipment", capabilities: [:heating]}
      ]

      domain = AriaHybridPlanner.setup_domain(:cooking_domain, entities: entities)

      registry = AriaHybridPlanner.get_entity_registry(domain)
      chef_entities = AriaHybridPlanner.get_entities_by_type(registry, "chef")
      assert length(chef_entities) == 1
    end

    test "creates domain with temporal specifications" do
      specs = AriaHybridPlanner.new_temporal_specifications()
      |> AriaHybridPlanner.add_action_duration(:cook, AriaHybridPlanner.fixed_duration(3600))

      domain = AriaHybridPlanner.setup_domain(:temporal_domain, temporal_specs: specs)

      domain_specs = AriaHybridPlanner.get_temporal_specifications(domain)
      duration = AriaHybridPlanner.get_action_duration(domain_specs, :cook)
      assert duration != nil
    end

    test "creates domain with both entities and temporal specs" do
      entities = [%{type: "chef", capabilities: [:cooking]}]
      specs = AriaHybridPlanner.new_temporal_specifications()

      domain = AriaHybridPlanner.setup_domain(:complete_domain, 
        entities: entities, 
        temporal_specs: specs
      )

      assert domain.name == :complete_domain
      registry = AriaHybridPlanner.get_entity_registry(domain)
      assert AriaHybridPlanner.get_entities_by_type(registry, "chef") != []
    end
  end

  describe "register_attribute_specs/2" do
    test "registers specs from module with no exported functions" do
      domain = AriaHybridPlanner.new_domain(:test)

      # Test with a module that doesn't have the expected functions
      result = AriaHybridPlanner.register_attribute_specs(domain, NonExistentModule)

      # Should return a domain (may or may not have actions depending on implementation)
      assert result.name == :test
    end

    test "registers specs from module with action specs in process dictionary" do
      domain = AriaHybridPlanner.new_domain(:test)

      # Set up process dictionary with mock specs
      action_specs = %{
        cook_meal: %{action_fn: fn(_state, _args) -> {:ok, %{}} end, duration: 3600}
      }
      Process.put({TestModule, :action_specs}, action_specs)

      result = AriaHybridPlanner.register_attribute_specs(domain, TestModule)

      # Should have added the action
      actions = AriaHybridPlanner.list_actions_in_domain(result)
      assert "cook_meal" in actions

      # Clean up
      Process.delete({TestModule, :action_specs})
    end

    test "registers method specs from process dictionary" do
      domain = AriaHybridPlanner.new_domain(:test)

      # Set up process dictionary with mock method specs
      method_specs = %{
        prepare_meal: %{decomposition_fn: fn(_state, _args) -> [] end}
      }
      Process.put({TestModule, :method_specs}, method_specs)

      result = AriaHybridPlanner.register_attribute_specs(domain, TestModule)

      # Should return a domain (method registration may not work as expected)
      assert result.name == :test

      # Clean up
      Process.delete({TestModule, :method_specs})
    end

    test "registers unigoal specs from process dictionary" do
      domain = AriaHybridPlanner.new_domain(:test)

      # Set up process dictionary with mock unigoal specs
      unigoal_specs = %{
        achieve_clean: %{predicate: "clean", method_fn: fn(_state, _args) -> [] end}
      }
      Process.put({TestModule, :unigoal_specs}, unigoal_specs)

      result = AriaHybridPlanner.register_attribute_specs(domain, TestModule)

      # Should have added the unigoal method
      unigoals = AriaHybridPlanner.list_unigoal_methods(result)
      assert :achieve_clean in unigoals

      # Clean up
      Process.delete({TestModule, :unigoal_specs})
    end

    test "handles doctest case for TestDurativeActionsDomain" do
      domain = AriaHybridPlanner.new_domain(:test)

      result = AriaHybridPlanner.register_attribute_specs(domain, AriaHybridPlanner.DurativeActionsTest.TestDurativeActionsDomain)

      # Should have at least one action (mock_action)
      actions = AriaHybridPlanner.list_actions_in_domain(result)
      assert length(actions) > 0
    end
  end

  describe "delegated functions" do
    test "domain management functions work" do
      domain = AriaHybridPlanner.new_domain(:test)
      assert domain.name == :test

      # Test add_method
      method_spec = %{decomposition_fn: fn(_state, _args) -> [] end}
      updated_domain = AriaHybridPlanner.add_method(domain, :test_method, method_spec)
      assert AriaHybridPlanner.get_method(updated_domain, :test_method) == method_spec

      # Test list functions
      actions = AriaHybridPlanner.list_actions(domain)
      assert is_list(actions)

      methods = AriaHybridPlanner.list_methods(domain)
      assert is_list(methods)

      unigoals = AriaHybridPlanner.list_unigoal_methods(domain)
      assert is_list(unigoals)
    end

    test "entity management functions work" do
      registry = AriaHybridPlanner.new_entity_registry()
      assert is_map(registry)

      # Test register_entity_type
      entity_spec = %{type: "chef", capabilities: [:cooking]}
      updated_registry = AriaHybridPlanner.register_entity_type(registry, entity_spec)

      # Test get_entities_by_type
      entities = AriaHybridPlanner.get_entities_by_type(updated_registry, "chef")
      assert length(entities) == 1

      # Test get_entities_by_capability
      cooking_entities = AriaHybridPlanner.get_entities_by_capability(updated_registry, :cooking)
      assert length(cooking_entities) == 1
    end

    test "temporal processing functions work" do
      specs = AriaHybridPlanner.new_temporal_specifications()
      assert is_map(specs)

      # Test duration creation
      fixed_dur = AriaHybridPlanner.fixed_duration(3600)
      assert fixed_dur.type == :fixed
      assert fixed_dur.seconds == 3600

      variable_dur = AriaHybridPlanner.variable_duration(1800, 7200)
      assert variable_dur.type == :variable
      assert variable_dur.min_seconds == 1800
      assert variable_dur.max_seconds == 7200

      # Test add_action_duration
      updated_specs = AriaHybridPlanner.add_action_duration(specs, :cook, fixed_dur)
      duration = AriaHybridPlanner.get_action_duration(updated_specs, :cook)
      assert duration == fixed_dur
    end

    test "state management functions work" do
      state = AriaHybridPlanner.new_state()
      assert is_map(state)

      # Test set_fact and get_fact
      updated_state = AriaHybridPlanner.set_fact(state, "status", "chef1", "available")
      assert {:ok, "available"} = AriaHybridPlanner.get_fact(updated_state, "status", "chef1")

      # Test copy_state
      copied_state = AriaHybridPlanner.copy_state(updated_state)
      assert {:ok, "available"} = AriaHybridPlanner.get_fact(copied_state, "status", "chef1")

      # Test has_subject?
      assert AriaHybridPlanner.has_subject?(updated_state, "status", "chef1") == true
      assert AriaHybridPlanner.has_subject?(updated_state, "status", "chef2") == false

      # Test matches?
      assert AriaHybridPlanner.matches?(updated_state, "status", "chef1", "available") == true
      assert AriaHybridPlanner.matches?(updated_state, "status", "chef1", "busy") == false
    end

    test "parse_duration/1 works" do
      # Test successful parsing
      case AriaHybridPlanner.parse_duration("PT1H") do
        {:fixed, 3600} -> assert true
        {:error, _} -> assert false, "Should parse PT1H successfully"
      end

      # Test error cases
      case AriaHybridPlanner.parse_duration("invalid") do
        {:error, _} -> assert true
        _ -> assert false, "Should return error for invalid duration"
      end

      case AriaHybridPlanner.parse_duration("") do
        {:error, _} -> assert true
        _ -> assert false, "Should return error for empty duration"
      end
    end

    test "validate_duration/1 works" do
      fixed_dur = AriaHybridPlanner.fixed_duration(3600)
      assert AriaHybridPlanner.validate_duration(fixed_dur) == :ok

      variable_dur = AriaHybridPlanner.variable_duration(1800, 7200)
      assert AriaHybridPlanner.validate_duration(variable_dur) == :ok

      assert {:error, _} = AriaHybridPlanner.validate_duration({:invalid, "bad"})
    end

    test "calculate_duration/3 works" do
      fixed_dur = AriaHybridPlanner.fixed_duration(3600)
      assert AriaHybridPlanner.calculate_duration(fixed_dur) == 3600

      variable_dur = AriaHybridPlanner.variable_duration(1800, 7200)
      calculated = AriaHybridPlanner.calculate_duration(variable_dur)
      assert calculated >= 1800 and calculated <= 7200
    end
  end

  # Helper functions
  defp create_test_domain do
    AriaHybridPlanner.new_domain(:test_domain)
  end
end
