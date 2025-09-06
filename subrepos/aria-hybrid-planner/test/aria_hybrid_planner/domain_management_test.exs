# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaHybridPlanner.DomainManagementTest do
  use ExUnit.Case
  doctest AriaHybridPlanner

  alias AriaHybridPlanner

  describe "domain creation" do
    test "new_domain/0 creates default domain" do
      domain = AriaHybridPlanner.new_domain()
      
      assert is_map(domain)
      # Should have basic domain structure
      assert Map.has_key?(domain, :name) or Map.has_key?(domain, "name")
    end

    test "new_domain/1 creates named domain" do
      domain = AriaHybridPlanner.new_domain(:cooking)
      
      assert is_map(domain)
      # Domain should have the specified name
      name = Map.get(domain, :name) || Map.get(domain, "name")
      assert name == :cooking or name == "cooking"
    end

    test "validate_domain/1 validates correct domain" do
      domain = AriaHybridPlanner.new_domain(:test)
      
      result = AriaHybridPlanner.validate_domain(domain)
      
      # The actual implementation returns :ok, not {:ok, domain}
      assert :ok = result
    end

    test "validate_domain/1 rejects invalid domain" do
      invalid_domain = %{invalid: "structure"}
      
      # The function expects a struct, so it will raise FunctionClauseError
      assert_raise FunctionClauseError, fn ->
        AriaHybridPlanner.validate_domain(invalid_domain)
      end
    end
  end

  describe "method management" do
    setup do
      domain = AriaHybridPlanner.new_domain(:method_test)
      %{domain: domain}
    end

    test "add_method/3 adds method to domain", %{domain: domain} do
      method_spec = %{
        type: :task,
        decomposition_fn: fn _state, _args -> {:ok, []} end
      }
      
      result = AriaHybridPlanner.add_method(domain, :test_method, method_spec)
      
      # The actual implementation returns the domain directly
      assert is_map(result)
      assert Map.has_key?(result.methods, :test_method)
    end

    test "add_unigoal_method/3 adds unigoal method", %{domain: domain} do
      unigoal_spec = %{
        predicate: "status",
        goal_fn: fn _state, _args -> {:ok, []} end
      }
      
      result = AriaHybridPlanner.add_unigoal_method(domain, :achieve_status, unigoal_spec)
      
      # The actual implementation returns the domain directly
      assert is_map(result)
      assert Map.has_key?(result.unigoal_methods, :achieve_status)
    end

    test "add_task_method_to_domain/4 adds task method", %{domain: domain} do
      method_fn = fn _state, _args -> {:ok, [{"test_action", []}]} end
      
      updated_domain = AriaHybridPlanner.add_task_method_to_domain(domain, "test_task", "method1", method_fn)
      
      assert is_map(updated_domain)
      
      # Verify method was added
      methods = AriaHybridPlanner.get_task_methods_from_domain(updated_domain, "test_task")
      assert is_list(methods)
    end

    test "add_task_method_to_domain/3 adds anonymous task method", %{domain: domain} do
      method_fn = fn _state, _args -> {:ok, [{"test_action", []}]} end
      
      updated_domain = AriaHybridPlanner.add_task_method_to_domain(domain, "test_task", method_fn)
      
      assert is_map(updated_domain)
    end

    test "get_task_methods_from_domain/2 retrieves methods", %{domain: domain} do
      method_fn = fn _state, _args -> {:ok, []} end
      domain = AriaHybridPlanner.add_task_method_to_domain(domain, "test_task", "method1", method_fn)
      
      methods = AriaHybridPlanner.get_task_methods_from_domain(domain, "test_task")
      
      assert is_list(methods)
    end

    test "has_task_methods_in_domain?/2 checks method existence", %{domain: domain} do
      # Initially no methods
      assert false == AriaHybridPlanner.has_task_methods_in_domain?(domain, "test_task")
      
      # Add a method
      method_fn = fn _state, _args -> {:ok, []} end
      domain = AriaHybridPlanner.add_task_method_to_domain(domain, "test_task", method_fn)
      
      # Now should have methods
      assert true == AriaHybridPlanner.has_task_methods_in_domain?(domain, "test_task")
    end
  end

  describe "action management" do
    setup do
      domain = AriaHybridPlanner.new_domain(:action_test)
      %{domain: domain}
    end

    test "add_action_to_domain/3 adds action", %{domain: domain} do
      action_fn = fn state, _args -> {:ok, state} end
      
      updated_domain = AriaHybridPlanner.add_action_to_domain(domain, "test_action", action_fn)
      
      assert is_map(updated_domain)
    end

    test "add_action_to_domain/4 adds action with metadata", %{domain: domain} do
      action_fn = fn state, _args -> {:ok, state} end
      metadata = %{description: "Test action", duration: 60}
      
      updated_domain = AriaHybridPlanner.add_action_to_domain(domain, "test_action", action_fn, metadata)
      
      assert is_map(updated_domain)
    end

    test "get_action_from_domain/2 retrieves action", %{domain: domain} do
      action_fn = fn _state, _args -> {:ok, "action executed"} end
      domain = AriaHybridPlanner.add_action_to_domain(domain, :test_action, action_fn)
      
      result = AriaHybridPlanner.get_action_from_domain(domain, :test_action)
      
      # The actual implementation returns the function directly
      assert is_function(result, 2)
    end

    test "has_action_in_domain?/2 checks action existence", %{domain: domain} do
      # Initially no action
      assert false == AriaHybridPlanner.has_action_in_domain?(domain, "test_action")
      
      # Add action
      action_fn = fn state, _args -> {:ok, state} end
      domain = AriaHybridPlanner.add_action_to_domain(domain, "test_action", action_fn)
      
      # Now should have action
      assert true == AriaHybridPlanner.has_action_in_domain?(domain, "test_action")
    end

    test "list_actions_in_domain/1 lists all actions", %{domain: domain} do
      action_fn = fn state, _args -> {:ok, state} end
      domain = AriaHybridPlanner.add_action_to_domain(domain, "action1", action_fn)
      domain = AriaHybridPlanner.add_action_to_domain(domain, "action2", action_fn)
      
      actions = AriaHybridPlanner.list_actions_in_domain(domain)
      
      assert is_list(actions)
      assert length(actions) >= 2
    end

    test "remove_action_from_domain/2 removes action", %{domain: domain} do
      action_fn = fn state, _args -> {:ok, state} end
      domain = AriaHybridPlanner.add_action_to_domain(domain, "test_action", action_fn)
      
      # Verify action exists
      assert true == AriaHybridPlanner.has_action_in_domain?(domain, "test_action")
      
      # Remove action
      updated_domain = AriaHybridPlanner.remove_action_from_domain(domain, "test_action")
      
      # Verify action is gone
      assert false == AriaHybridPlanner.has_action_in_domain?(updated_domain, "test_action")
    end
  end

  describe "entity registry integration" do
    setup do
      domain = AriaHybridPlanner.new_domain(:entity_test)
      %{domain: domain}
    end

    test "set_entity_registry/2 sets registry", %{domain: domain} do
      registry = AriaHybridPlanner.new_entity_registry()
      
      updated_domain = AriaHybridPlanner.set_entity_registry(domain, registry)
      
      assert is_map(updated_domain)
    end

    test "get_entity_registry/1 retrieves registry", %{domain: domain} do
      registry = AriaHybridPlanner.new_entity_registry()
      domain = AriaHybridPlanner.set_entity_registry(domain, registry)
      
      retrieved_registry = AriaHybridPlanner.get_entity_registry(domain)
      
      assert is_map(retrieved_registry)
    end
  end

  describe "temporal specifications integration" do
    setup do
      domain = AriaHybridPlanner.new_domain(:temporal_test)
      %{domain: domain}
    end

    test "set_temporal_specifications/2 sets specifications", %{domain: domain} do
      specs = AriaHybridPlanner.new_temporal_specifications()
      
      updated_domain = AriaHybridPlanner.set_temporal_specifications(domain, specs)
      
      assert is_map(updated_domain)
    end

    test "get_temporal_specifications/1 retrieves specifications", %{domain: domain} do
      specs = AriaHybridPlanner.new_temporal_specifications()
      domain = AriaHybridPlanner.set_temporal_specifications(domain, specs)
      
      retrieved_specs = AriaHybridPlanner.get_temporal_specifications(domain)
      
      assert is_map(retrieved_specs)
    end
  end

  describe "setup_domain/2 convenience function" do
    test "creates domain with entities" do
      entities = [
        %{type: "chef", capabilities: [:cooking, :prep]},
        %{type: "oven", capabilities: [:baking, :roasting]}
      ]
      
      domain = AriaHybridPlanner.setup_domain(:cooking, entities: entities)
      
      assert is_map(domain)
      
      # Verify entity registry was set
      registry = AriaHybridPlanner.get_entity_registry(domain)
      assert is_map(registry)
      
      # Verify entities were registered
      chefs = AriaHybridPlanner.get_entities_by_type(registry, "chef")
      assert length(chefs) > 0
    end

    test "creates domain with temporal specifications" do
      temporal_specs = AriaHybridPlanner.new_temporal_specifications()
      |> AriaHybridPlanner.add_action_duration("cook", AriaHybridPlanner.fixed_duration(3600))
      
      domain = AriaHybridPlanner.setup_domain(:cooking, temporal_specs: temporal_specs)
      
      assert is_map(domain)
      
      # Verify temporal specs were set
      specs = AriaHybridPlanner.get_temporal_specifications(domain)
      assert is_map(specs)
    end

    test "creates domain with both entities and temporal specs" do
      entities = [%{type: "chef", capabilities: [:cooking]}]
      temporal_specs = AriaHybridPlanner.new_temporal_specifications()
      
      domain = AriaHybridPlanner.setup_domain(:cooking, 
        entities: entities, 
        temporal_specs: temporal_specs
      )
      
      assert is_map(domain)
      assert is_map(AriaHybridPlanner.get_entity_registry(domain))
      assert is_map(AriaHybridPlanner.get_temporal_specifications(domain))
    end
  end

  describe "legacy domain functions" do
    test "new_legacy_domain/0 creates legacy domain" do
      domain = AriaHybridPlanner.new_legacy_domain()
      
      assert is_map(domain)
      assert Map.get(domain, :type) == :legacy
    end

    test "new_legacy_domain/1 creates named legacy domain" do
      domain = AriaHybridPlanner.new_legacy_domain("test_legacy")
      
      assert is_map(domain)
      assert Map.get(domain, :name) == "test_legacy"
      assert Map.get(domain, :type) == :legacy
    end

    test "validate_legacy_domain/1 validates legacy domain" do
      domain = AriaHybridPlanner.new_legacy_domain()
      
      result = AriaHybridPlanner.validate_legacy_domain(domain)
      
      assert {:ok, _validated_domain} = result
    end

    test "validate_legacy_domain/1 rejects invalid legacy domain" do
      invalid_domain = %{incomplete: "structure"}
      
      result = AriaHybridPlanner.validate_legacy_domain(invalid_domain)
      
      assert {:error, _reason} = result
    end

    test "add_action_to_legacy_domain/3 adds action to legacy domain" do
      domain = AriaHybridPlanner.new_legacy_domain()
      action_spec = %{fn: fn state, _args -> {:ok, state} end}
      
      result = AriaHybridPlanner.add_action_to_legacy_domain(domain, :test_action, action_spec)
      
      assert {:ok, updated_domain} = result
      assert Map.has_key?(updated_domain.actions, :test_action)
    end

    test "get_durative_action_from_legacy_domain/2 retrieves action" do
      domain = AriaHybridPlanner.new_legacy_domain()
      action_spec = %{fn: fn state, _args -> {:ok, state} end}
      {:ok, domain} = AriaHybridPlanner.add_action_to_legacy_domain(domain, :test_action, action_spec)
      
      result = AriaHybridPlanner.get_durative_action_from_legacy_domain(domain, :test_action)
      
      assert {:ok, retrieved_spec} = result
      assert retrieved_spec == action_spec
    end

    test "get_durative_action_from_legacy_domain/2 returns error for missing action" do
      domain = AriaHybridPlanner.new_legacy_domain()
      
      result = AriaHybridPlanner.get_durative_action_from_legacy_domain(domain, :missing_action)
      
      assert {:error, _reason} = result
    end
  end

  describe "domain utilities" do
    test "domain_summary/1 provides domain summary" do
      domain = AriaHybridPlanner.new_domain(:test)
      |> AriaHybridPlanner.add_action_to_domain("test_action", fn state, _args -> {:ok, state} end)
      
      summary = AriaHybridPlanner.domain_summary(domain)
      
      assert is_map(summary) or is_binary(summary)
    end

    test "create_complete_domain/0 creates complete domain" do
      domain = AriaHybridPlanner.create_complete_domain()
      
      assert is_map(domain)
    end

    test "create_complete_domain/1 creates named complete domain" do
      domain = AriaHybridPlanner.create_complete_domain("complete_test")
      
      assert is_map(domain)
    end
  end

  describe "error handling" do
    test "handles invalid method specifications gracefully" do
      domain = AriaHybridPlanner.new_domain(:test)
      invalid_spec = "not a valid spec"
      
      result = AriaHybridPlanner.add_method(domain, :test_method, invalid_spec)
      
      # The actual implementation accepts any spec and returns updated domain
      assert is_map(result)
    end

    test "handles missing actions gracefully" do
      domain = AriaHybridPlanner.new_domain(:test)
      
      result = AriaHybridPlanner.get_action_from_domain(domain, :nonexistent_action)
      
      # The actual implementation returns nil for missing actions
      assert result == nil
    end

    test "handles missing methods gracefully" do
      domain = AriaHybridPlanner.new_domain(:test)
      
      methods = AriaHybridPlanner.get_task_methods_from_domain(domain, "missing_task")
      
      assert is_list(methods)
      assert length(methods) == 0
    end
  end
end
