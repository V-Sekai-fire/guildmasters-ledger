# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.DomainPlanningTest do
  use ExUnit.Case, async: true
  doctest AriaCore.DomainPlanning

  alias AriaCore.DomainPlanning

  describe "new_legacy_domain/1" do
    test "creates a new legacy domain with default name" do
      domain = DomainPlanning.new_legacy_domain()

      assert domain.name == "default"
      assert domain.actions == %{}
      assert domain.action_metadata == %{}
      assert domain.task_methods == %{}
      assert domain.unigoal_methods == %{}
      assert domain.multigoal_methods == []
      assert domain.multitodo_methods == []
      assert domain.durative_actions == %{}
    end

    test "creates a new legacy domain with custom name" do
      domain = DomainPlanning.new_legacy_domain("test_domain")

      assert domain.name == "test_domain"
      assert domain.actions == %{}
      assert domain.action_metadata == %{}
      assert domain.task_methods == %{}
      assert domain.unigoal_methods == %{}
      assert domain.multigoal_methods == []
      assert domain.multitodo_methods == []
      assert domain.durative_actions == %{}
    end

    test "creates domain with proper structure for all fields" do
      domain = DomainPlanning.new_legacy_domain("blocks_world")

      # Verify all required fields are present
      assert Map.has_key?(domain, :name)
      assert Map.has_key?(domain, :actions)
      assert Map.has_key?(domain, :action_metadata)
      assert Map.has_key?(domain, :task_methods)
      assert Map.has_key?(domain, :unigoal_methods)
      assert Map.has_key?(domain, :multigoal_methods)
      assert Map.has_key?(domain, :multitodo_methods)
      assert Map.has_key?(domain, :durative_actions)

      # Verify correct types
      assert is_binary(domain.name)
      assert is_map(domain.actions)
      assert is_map(domain.action_metadata)
      assert is_map(domain.task_methods)
      assert is_map(domain.unigoal_methods)
      assert is_list(domain.multigoal_methods)
      assert is_list(domain.multitodo_methods)
      assert is_map(domain.durative_actions)
    end
  end

  describe "validate_legacy_domain/1" do
    test "validates a correct legacy domain" do
      domain = DomainPlanning.new_legacy_domain("valid_domain")

      result = DomainPlanning.validate_legacy_domain(domain)
      assert {:ok, ^domain} = result
    end

    test "rejects domain with empty name" do
      domain = DomainPlanning.new_legacy_domain("")

      result = DomainPlanning.validate_legacy_domain(domain)
      assert {:error, "Domain name cannot be empty"} = result
    end

    test "rejects domain with nil name" do
      domain = %{DomainPlanning.new_legacy_domain() | name: nil}

      result = DomainPlanning.validate_legacy_domain(domain)
      assert {:error, "Domain name cannot be empty"} = result
    end

    test "rejects domain with non-map actions" do
      domain = %{DomainPlanning.new_legacy_domain() | actions: []}

      result = DomainPlanning.validate_legacy_domain(domain)
      assert {:error, "Actions must be a map"} = result
    end

    test "rejects domain with non-map action_metadata" do
      domain = %{DomainPlanning.new_legacy_domain() | action_metadata: "invalid"}

      result = DomainPlanning.validate_legacy_domain(domain)
      assert {:error, "Action metadata must be a map"} = result
    end

    test "rejects domain with non-map task_methods" do
      domain = %{DomainPlanning.new_legacy_domain() | task_methods: []}

      result = DomainPlanning.validate_legacy_domain(domain)
      assert {:error, "Task methods must be a map"} = result
    end

    test "rejects domain with non-map unigoal_methods" do
      domain = %{DomainPlanning.new_legacy_domain() | unigoal_methods: "invalid"}

      result = DomainPlanning.validate_legacy_domain(domain)
      assert {:error, "Unigoal methods must be a map"} = result
    end

    test "rejects domain with non-list multigoal_methods" do
      domain = %{DomainPlanning.new_legacy_domain() | multigoal_methods: %{}}

      result = DomainPlanning.validate_legacy_domain(domain)
      assert {:error, "Multigoal methods must be a list"} = result
    end

    test "rejects domain with non-list multitodo_methods" do
      domain = %{DomainPlanning.new_legacy_domain() | multitodo_methods: %{}}

      result = DomainPlanning.validate_legacy_domain(domain)
      assert {:error, "Multitodo methods must be a list"} = result
    end

    test "rejects domain with non-map durative_actions" do
      domain = %{DomainPlanning.new_legacy_domain() | durative_actions: []}

      result = DomainPlanning.validate_legacy_domain(domain)
      assert {:error, "Durative actions must be a map"} = result
    end

    test "rejects non-map input" do
      result = DomainPlanning.validate_legacy_domain("not a map")
      assert {:error, "Not a valid domain map"} = result

      result = DomainPlanning.validate_legacy_domain(123)
      assert {:error, "Not a valid domain map"} = result

      result = DomainPlanning.validate_legacy_domain([])
      assert {:error, "Not a valid domain map"} = result
    end

    test "validates domain with populated fields" do
      action_fn = fn _state, _args -> AriaState.new() end
      method_fn = fn _state, _args -> [] end

      domain = %{
        name: "populated_domain",
        actions: %{move: action_fn},
        action_metadata: %{move: %{duration: 5}},
        task_methods: %{"move_block" => [{"method1", method_fn}]},
        unigoal_methods: %{"achieve_pos" => [{"method1", method_fn}]},
        multigoal_methods: [{"multigoal_method", method_fn}],
        multitodo_methods: [{"multitodo_method", method_fn}],
        durative_actions: %{move_slowly: %{duration: 10}}
      }

      result = DomainPlanning.validate_legacy_domain(domain)
      assert {:ok, ^domain} = result
    end
  end

  describe "get_durative_action_from_legacy_domain/2" do
    test "retrieves existing durative action" do
      durative_action = %{duration: 5, preconditions: [], effects: []}
      domain = %{
        DomainPlanning.new_legacy_domain() |
        durative_actions: %{move: durative_action}
      }

      result = DomainPlanning.get_durative_action_from_legacy_domain(domain, :move)
      assert result == durative_action
    end

    test "returns nil for non-existing durative action" do
      domain = DomainPlanning.new_legacy_domain()

      result = DomainPlanning.get_durative_action_from_legacy_domain(domain, :nonexistent)
      assert result == nil
    end

    test "handles multiple durative actions" do
      move_action = %{duration: 5, type: :move}
      pickup_action = %{duration: 2, type: :pickup}
      
      domain = %{
        DomainPlanning.new_legacy_domain() |
        durative_actions: %{
          move: move_action,
          pickup: pickup_action
        }
      }

      assert DomainPlanning.get_durative_action_from_legacy_domain(domain, :move) == move_action
      assert DomainPlanning.get_durative_action_from_legacy_domain(domain, :pickup) == pickup_action
      assert DomainPlanning.get_durative_action_from_legacy_domain(domain, :drop) == nil
    end
  end

  describe "convert_to_legacy_domain/1" do
    test "converts modern domain to legacy format" do
      # Create a mock modern domain
      modern_domain = %AriaCore.Domain{
        name: :test_domain,
        actions: %{move: fn _state, _args -> AriaState.new() end},
        methods: %{"move_block" => []},
        unigoal_methods: %{"achieve_pos" => []},
        entity_registry: %{},
        temporal_specifications: %{},
        state_predicates: %{}
      }

      legacy_domain = DomainPlanning.convert_to_legacy_domain(modern_domain)

      assert legacy_domain.name == "test_domain"
      assert legacy_domain.actions == modern_domain.actions
      assert legacy_domain.action_metadata == %{}
      assert legacy_domain.task_methods == modern_domain.methods
      assert legacy_domain.unigoal_methods == modern_domain.unigoal_methods
      assert legacy_domain.multigoal_methods == []
      assert legacy_domain.multitodo_methods == []
      assert legacy_domain.durative_actions == %{}
    end

    test "handles domain with empty collections" do
      modern_domain = %AriaCore.Domain{
        name: :empty_domain,
        actions: %{},
        methods: %{},
        unigoal_methods: %{},
        entity_registry: %{},
        temporal_specifications: %{},
        state_predicates: %{}
      }

      legacy_domain = DomainPlanning.convert_to_legacy_domain(modern_domain)

      assert legacy_domain.name == "empty_domain"
      assert legacy_domain.actions == %{}
      assert legacy_domain.task_methods == %{}
      assert legacy_domain.unigoal_methods == %{}
    end
  end

  describe "convert_from_legacy_domain/1" do
    test "converts legacy domain to modern format" do
      action_fn = fn _state, _args -> AriaState.new() end
      method_fn = fn _state, _args -> [] end

      legacy_domain = %{
        name: "test_domain",
        actions: %{move: action_fn},
        action_metadata: %{move: %{duration: 5}},
        task_methods: %{"move_block" => [{"method1", method_fn}]},
        unigoal_methods: %{"achieve_pos" => [{"method1", method_fn}]},
        multigoal_methods: [],
        multitodo_methods: [],
        durative_actions: %{}
      }

      modern_domain = DomainPlanning.convert_from_legacy_domain(legacy_domain)

      assert modern_domain.name == :test_domain
      assert modern_domain.actions == legacy_domain.actions
      assert modern_domain.methods == legacy_domain.task_methods
      assert modern_domain.unigoal_methods == legacy_domain.unigoal_methods
      assert is_map(modern_domain.entity_registry)
      assert is_map(modern_domain.temporal_specifications)
      assert modern_domain.state_predicates == %{}
    end

    test "handles legacy domain with atom name" do
      legacy_domain = %{
        name: :atom_name,
        actions: %{},
        task_methods: %{},
        unigoal_methods: %{}
      }

      modern_domain = DomainPlanning.convert_from_legacy_domain(legacy_domain)
      assert modern_domain.name == :atom_name
    end

    test "handles legacy domain with missing fields" do
      legacy_domain = %{name: "minimal_domain"}

      modern_domain = DomainPlanning.convert_from_legacy_domain(legacy_domain)

      assert modern_domain.name == :minimal_domain
      assert modern_domain.actions == %{}
      assert modern_domain.methods == %{}
      assert modern_domain.unigoal_methods == %{}
    end

    test "handles legacy domain with invalid name" do
      legacy_domain = %{name: nil}

      modern_domain = DomainPlanning.convert_from_legacy_domain(legacy_domain)
      assert modern_domain.name == :converted_domain
    end
  end

  describe "integration scenarios" do
    test "round-trip conversion preserves core data" do
      # Start with a legacy domain
      original_legacy = %{
        name: "round_trip_test",
        actions: %{move: fn _state, _args -> AriaState.new() end},
        action_metadata: %{},
        task_methods: %{"move_block" => []},
        unigoal_methods: %{"achieve_pos" => []},
        multigoal_methods: [],
        multitodo_methods: [],
        durative_actions: %{}
      }

      # Convert to modern and back to legacy
      modern = DomainPlanning.convert_from_legacy_domain(original_legacy)
      final_legacy = DomainPlanning.convert_to_legacy_domain(modern)

      # Verify core data is preserved
      assert final_legacy.name == original_legacy.name
      assert final_legacy.actions == original_legacy.actions
      assert final_legacy.task_methods == original_legacy.task_methods
      assert final_legacy.unigoal_methods == original_legacy.unigoal_methods
    end

    test "validation works with converted domains" do
      legacy_domain = DomainPlanning.new_legacy_domain("validation_test")
      modern_domain = DomainPlanning.convert_from_legacy_domain(legacy_domain)
      converted_back = DomainPlanning.convert_to_legacy_domain(modern_domain)

      result = DomainPlanning.validate_legacy_domain(converted_back)
      assert {:ok, _} = result
    end

    test "durative actions work with populated domain" do
      durative_action = %{
        duration: 10,
        preconditions: [{"clear", "?x", true}],
        effects: [{"pos", "?x", "?y"}]
      }

      domain = %{
        DomainPlanning.new_legacy_domain("durative_test") |
        durative_actions: %{move_slowly: durative_action}
      }

      # Validate domain
      assert {:ok, _} = DomainPlanning.validate_legacy_domain(domain)

      # Retrieve durative action
      retrieved = DomainPlanning.get_durative_action_from_legacy_domain(domain, :move_slowly)
      assert retrieved == durative_action
    end
  end
end
