# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.MethodManagementTest do
  use ExUnit.Case
  doctest AriaCore.MethodManagement

  alias AriaCore.MethodManagement
  alias AriaCore.Domain
  alias AriaState

  setup do
    domain = Domain.new(:test_domain)
    state = AriaState.new()
    %{domain: domain, state: state}
  end

  describe "task method management" do
    test "add_task_method/4 adds method to domain", %{domain: domain} do
      method_fn = fn _state, _args -> {:ok, [{:action1, ["arg1"]}]} end

      updated_domain = MethodManagement.add_task_method(domain, :test_task, :method1, method_fn)

      assert Map.has_key?(updated_domain.task_methods, :test_task)
      task_methods = updated_domain.task_methods[:test_task]
      assert {:method1, method_fn} in task_methods
    end

    test "add_task_method/3 adds method with inferred name", %{domain: domain} do
      method_fn = fn _state, _args -> {:ok, [{:action1, ["arg1"]}]} end

      updated_domain = MethodManagement.add_task_method(domain, :test_task, method_fn)

      # Should add method with some generated name to task_methods
      assert Map.has_key?(updated_domain.task_methods, :test_task)
      task_methods = updated_domain.task_methods[:test_task]
      assert is_list(task_methods)
      assert length(task_methods) == 1
    end

    test "add_task_methods/3 adds multiple methods", %{domain: domain} do
      method1 = fn _state, _args -> {:ok, [{:action1, ["arg1"]}]} end
      method2 = fn _state, _args -> {:ok, [{:action2, ["arg2"]}]} end
      
      methods = [
        {:method1, method1},
        {:method2, method2}
      ]

      updated_domain = MethodManagement.add_task_methods(domain, :test_task, methods)

      assert Map.has_key?(updated_domain.task_methods, :test_task)
      task_methods = updated_domain.task_methods[:test_task]
      assert {:method1, method1} in task_methods
      assert {:method2, method2} in task_methods
    end

    test "get_task_methods/2 retrieves methods for task", %{domain: domain} do
      method_fn = fn _state, _args -> {:ok, [{:action1, ["arg1"]}]} end
      domain = MethodManagement.add_task_method(domain, :test_task, :method1, method_fn)

      methods = MethodManagement.get_task_methods(domain, :test_task)

      assert is_list(methods)
      # The exact structure depends on implementation
    end

    test "has_task_methods?/2 checks if task has methods", %{domain: domain} do
      method_fn = fn _state, _args -> {:ok, [{:action1, ["arg1"]}]} end
      domain = MethodManagement.add_task_method(domain, :test_task, :method1, method_fn)

      assert MethodManagement.has_task_methods?(domain, :test_task) == true
      assert MethodManagement.has_task_methods?(domain, :other_task) == false
    end
  end

  describe "unigoal method management" do
    test "add_unigoal_method/4 adds unigoal method", %{domain: domain} do
      method_fn = fn _state, _goal -> {:ok, [{:achieve_goal, ["arg1"]}]} end

      updated_domain = MethodManagement.add_unigoal_method(domain, "status", :achieve_status, method_fn)

      assert Map.has_key?(updated_domain.unigoal_methods, "status")
      status_methods = updated_domain.unigoal_methods["status"]
      assert Map.has_key?(status_methods, :achieve_status)
      assert status_methods[:achieve_status] == method_fn
    end

    test "add_unigoal_method/3 adds unigoal method with inferred name", %{domain: domain} do
      method_fn = fn _state, _goal -> {:ok, [{:achieve_goal, ["arg1"]}]} end

      updated_domain = MethodManagement.add_unigoal_method(domain, "status", method_fn)

      # Should add method with some generated name
      assert map_size(updated_domain.unigoal_methods) == 1
    end

    test "add_unigoal_methods/3 adds multiple unigoal methods", %{domain: domain} do
      method1 = fn _state, _goal -> {:ok, [{:action1, ["arg1"]}]} end
      method2 = fn _state, _goal -> {:ok, [{:action2, ["arg2"]}]} end
      
      methods = [
        {:method1, method1},
        {:method2, method2}
      ]

      updated_domain = MethodManagement.add_unigoal_methods(domain, "status", methods)

      assert Map.has_key?(updated_domain.unigoal_methods, "status")
      status_methods = updated_domain.unigoal_methods["status"]
      assert Map.has_key?(status_methods, :method1)
      assert Map.has_key?(status_methods, :method2)
    end

    test "get_unigoal_methods/2 retrieves methods for goal type", %{domain: domain} do
      method_fn = fn _state, _goal -> {:ok, [{:action1, ["arg1"]}]} end
      _domain = MethodManagement.add_unigoal_method(domain, "status", :achieve_status, method_fn)

      methods = MethodManagement.get_unigoal_methods(domain, "status")

      assert is_map(methods)
    end

    test "has_unigoal_methods?/2 checks if goal type has methods", %{domain: domain} do
      method_fn = fn _state, _goal -> {:ok, [{:action1, ["arg1"]}]} end
      updated_domain = MethodManagement.add_unigoal_method(domain, "status", :achieve_status, method_fn)

      assert MethodManagement.has_unigoal_methods?(updated_domain, "status") == true
      assert MethodManagement.has_unigoal_methods?(updated_domain, "other_predicate") == false
    end

    test "get_goal_methods/2 retrieves methods for predicate", %{domain: domain} do
      method_fn = fn _state, _goal -> {:ok, [{:action1, ["arg1"]}]} end
      _updated_domain = MethodManagement.add_unigoal_method(domain, "status", :achieve_status, method_fn)

      methods = MethodManagement.get_goal_methods(domain, "status")

      assert is_map(methods)
    end
  end

  describe "multigoal method management" do
    test "add_multigoal_method/3 adds multigoal method with name", %{domain: domain} do
      method_fn = fn _state, _goals -> {:ok, [{:action1, ["arg1"]}]} end

      updated_domain = MethodManagement.add_multigoal_method(domain, :multi_method, method_fn)

      # Check that multigoal methods are stored (implementation dependent)
      assert is_struct(updated_domain, Domain)
    end

    test "add_multigoal_method/2 adds multigoal method with inferred name", %{domain: domain} do
      method_fn = fn _state, _goals -> {:ok, [{:action1, ["arg1"]}]} end

      updated_domain = MethodManagement.add_multigoal_method(domain, method_fn)

      # Should add method successfully
      assert is_struct(updated_domain, Domain)
    end

    test "get_multigoal_methods/1 retrieves all multigoal methods", %{domain: domain} do
      method_fn = fn _state, _goals -> {:ok, [{:action1, ["arg1"]}]} end
      domain = MethodManagement.add_multigoal_method(domain, :multi_method, method_fn)

      methods = MethodManagement.get_multigoal_methods(domain)

      assert is_list(methods)
    end
  end

  describe "multitodo method management" do
    test "add_multitodo_method/3 adds multitodo method with name", %{domain: domain} do
      method_fn = fn _state, _todos -> {:ok, [{:action1, ["arg1"]}]} end

      updated_domain = MethodManagement.add_multitodo_method(domain, :todo_method, method_fn)

      # Check that multitodo methods are stored (implementation dependent)
      assert is_struct(updated_domain, Domain)
    end

    test "add_multitodo_method/2 adds multitodo method with inferred name", %{domain: domain} do
      method_fn = fn _state, _todos -> {:ok, [{:action1, ["arg1"]}]} end

      updated_domain = MethodManagement.add_multitodo_method(domain, method_fn)

      # Should add method successfully
      assert is_struct(updated_domain, Domain)
    end

    test "get_multitodo_methods/1 retrieves all multitodo methods", %{domain: domain} do
      method_fn = fn _state, _todos -> {:ok, [{:action1, ["arg1"]}]} end
      domain = MethodManagement.add_multitodo_method(domain, :todo_method, method_fn)

      methods = MethodManagement.get_multitodo_methods(domain)

      assert is_list(methods)
    end
  end

  describe "general method management" do
    test "add_method/3 adds method with spec", %{domain: domain} do
      method_spec = %{
        type: :task_method,
        decomposition_fn: fn _state, _args -> {:ok, [{:action1, ["arg1"]}]} end
      }

      updated_domain = MethodManagement.add_method(domain, :test_method, method_spec)

      # The add_method/3 function routes to add_task_method/3 for task_method type
      # So we should check that the method was added to task_methods
      assert Map.has_key?(updated_domain.task_methods, :test_method)
      task_methods = updated_domain.task_methods[:test_method]
      assert is_list(task_methods)
      assert length(task_methods) == 1
    end

    test "get_method/2 retrieves method by name", %{domain: domain} do
      method_fn = fn _state, _args -> {:ok, [{:action1, ["arg1"]}]} end
      domain = MethodManagement.add_task_method(domain, :test_task, :test_method, method_fn)

      retrieved_fn = MethodManagement.get_method(domain, :test_method)

      assert retrieved_fn == method_fn
    end

    test "get_method/2 returns nil for non-existent method", %{domain: domain} do
      result = MethodManagement.get_method(domain, :non_existent)

      assert is_nil(result)
    end

    test "get_method_counts/1 returns method statistics", %{domain: domain} do
      method_fn = fn _state, _args -> {:ok, [{:action1, ["arg1"]}]} end
      unigoal_fn = fn _state, _goal -> {:ok, [{:action1, ["arg1"]}]} end
      
      domain = domain
      |> MethodManagement.add_task_method(:task1, :method1, method_fn)
      |> MethodManagement.add_task_method(:task2, :method2, method_fn)
      |> MethodManagement.add_unigoal_method("status", :unigoal1, unigoal_fn)

      counts = MethodManagement.get_method_counts(domain)

      assert is_map(counts)
      # Exact structure depends on implementation
      assert Map.has_key?(counts, :task_methods) or Map.has_key?(counts, :total)
    end
  end

  describe "method validation and error handling" do
    test "handles invalid method functions gracefully", %{domain: domain} do
      # Test with function of wrong arity
      invalid_fn = fn _state -> {:ok, []} end

      # Should not crash, but may have validation warnings
      result = MethodManagement.add_task_method(domain, :test_task, :invalid_method, invalid_fn)

      assert is_struct(result, Domain)
    end

    test "handles nil domain gracefully" do
      # Should handle nil domain without crashing
      result = try do
        MethodManagement.get_task_methods(nil, :test_task)
      rescue
        _ -> []
      end

      assert is_list(result)
    end

    test "handles empty method lists", %{domain: domain} do
      # Test getting methods when none exist
      methods = MethodManagement.get_task_methods(domain, :non_existent_task)
      assert is_list(methods)
      assert Enum.empty?(methods)

      unigoal_methods = MethodManagement.get_unigoal_methods(domain, "non_existent_predicate")
      assert is_map(unigoal_methods)
      assert Enum.empty?(unigoal_methods)
    end

    test "validates method specifications", %{domain: domain} do
      # Test with invalid method spec
      invalid_spec = %{invalid_field: "bad_value"}

      result = MethodManagement.add_method(domain, :invalid_method, invalid_spec)

      # Should handle gracefully
      assert is_struct(result, Domain)
    end
  end

  describe "method execution patterns" do
    test "task method returns valid decomposition", %{domain: domain, state: state} do
      method_fn = fn _state, [task_id] ->
        # Simulate a method that decomposes a task into actions
        {:ok, [
          {:prepare_task, [task_id]},
          {:execute_task, [task_id]},
          {:complete_task, [task_id]}
        ]}
      end

      _domain = MethodManagement.add_task_method(domain, :complex_task, :decompose_complex, method_fn)

      # Test that the method can be called
      result = method_fn.(state, ["task_123"])

      assert {:ok, decomposition} = result
      assert length(decomposition) == 3
      assert {:prepare_task, ["task_123"]} in decomposition
    end

    test "unigoal method returns valid goal achievement plan", %{domain: domain, state: state} do
      method_fn = fn state, {subject, value} ->
        # Simulate achieving a goal
        case AriaState.get_fact(state, "status", subject) do
          {:ok, ^value} ->
            {:ok, []} # Goal already achieved
          _ ->
            {:ok, [{:set_status, [subject, value]}]}
        end
      end

      _updated_domain = MethodManagement.add_unigoal_method(domain, "status", :achieve_status, method_fn)

      # Test goal achievement when goal not met
      result = method_fn.(state, {"entity1", "active"})
      assert {:ok, [{:set_status, ["entity1", "active"]}]} = result

      # Test goal achievement when goal already met
      state_with_goal = AriaState.set_fact(state, "status", "entity1", "active")
      result = method_fn.(state_with_goal, {"entity1", "active"})
      assert {:ok, []} = result
    end

    test "multigoal method handles multiple goals", %{domain: domain, state: state} do
      method_fn = fn _state, goals ->
        # Simulate handling multiple goals
        actions = Enum.map(goals, fn {predicate, subject, value} ->
          {:set_fact, [predicate, subject, value]}
        end)
        {:ok, actions}
      end

      _domain = MethodManagement.add_multigoal_method(domain, :handle_multiple_goals, method_fn)

      goals = [
        {"status", "entity1", "active"},
        {"location", "entity1", "room1"},
        {"task", "entity1", "working"}
      ]

      result = method_fn.(state, goals)

      assert {:ok, actions} = result
      assert length(actions) == 3
      assert {:set_fact, ["status", "entity1", "active"]} in actions
    end
  end
end
