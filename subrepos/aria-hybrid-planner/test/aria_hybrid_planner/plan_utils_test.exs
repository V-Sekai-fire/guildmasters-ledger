defmodule Plan.UtilsTest do
  use ExUnit.Case, async: true

  alias Plan.Utils
  alias AriaState

  describe "create_initial_solution_tree/2" do
    test "creates a solution tree with root node" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()

      tree = Utils.create_initial_solution_tree(todos, state)

      assert is_binary(tree.root_id)
      assert String.starts_with?(tree.root_id, "node_")
      assert Map.has_key?(tree.nodes, tree.root_id)

      root_node = tree.nodes[tree.root_id]
      assert root_node.task == {:root, todos}
      assert root_node.parent_id == nil
      assert root_node.children_ids == []
      assert root_node.state == state
      refute root_node.visited
      refute root_node.expanded
      assert root_node.method_tried == nil
      assert root_node.blacklisted_methods == []
      refute root_node.is_primitive
      refute root_node.is_durative
    end
  end

  describe "generate_node_id/0" do
    test "generates unique node IDs" do
      id1 = Utils.generate_node_id()
      id2 = Utils.generate_node_id()

      assert is_binary(id1)
      assert is_binary(id2)
      assert String.starts_with?(id1, "node_")
      assert String.starts_with?(id2, "node_")
      assert id1 != id2
    end
  end

  describe "plan_cost/1" do
    test "calculates cost as number of primitive actions" do
      # Create a simple tree with some primitive actions
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      # Mock some primitive actions by adding nodes
      primitive_node = %{
        id: Utils.generate_node_id(),
        task: {:move, ["player", "room1"]},
        parent_id: tree.root_id,
        children_ids: [],
        state: state,
        visited: true,
        expanded: true,
        method_tried: nil,
        blacklisted_methods: [],
        is_primitive: true,
        is_durative: false
      }

      updated_tree = %{tree | nodes: Map.put(tree.nodes, primitive_node.id, primitive_node)}
      updated_tree = %{updated_tree | nodes: Map.update!(updated_tree.nodes, tree.root_id, fn root ->
        %{root | children_ids: [primitive_node.id]}
      end)}

      cost = Utils.plan_cost(updated_tree)
      assert cost == 1
    end
  end

  describe "tree_stats/1" do
    test "returns statistics about the solution tree" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      stats = Utils.tree_stats(tree)

      assert stats.total_nodes == 1
      assert stats.primitive_nodes == 0
      assert stats.task_nodes == 1
      assert stats.action_count == 0
      assert stats.blacklisted_commands == 0
    end
  end

  describe "update_cached_states/2" do
    test "updates the root node state" do
      todos = [{:goal, "location", "player", "room1"}]
      initial_state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, initial_state)

      new_state = AriaState.set_fact(initial_state, "location", "player", "room2")
      updated_tree = Utils.update_cached_states(tree, new_state)

      root_node = updated_tree.nodes[updated_tree.root_id]
      assert root_node.state == new_state
    end
  end

  describe "get_all_descendants/2" do
    test "returns all descendant node IDs" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      # Add a child node
      child_id = Utils.generate_node_id()
      child_node = %{
        id: child_id,
        task: {:move, ["player", "room1"]},
        parent_id: tree.root_id,
        children_ids: [],
        state: state,
        visited: false,
        expanded: false,
        method_tried: nil,
        blacklisted_methods: [],
        is_primitive: false,
        is_durative: false
      }

      updated_tree = %{tree | nodes: Map.put(tree.nodes, child_id, child_node)}
      updated_tree = %{updated_tree | nodes: Map.update!(updated_tree.nodes, tree.root_id, fn root ->
        %{root | children_ids: [child_id]}
      end)}

      descendants = Utils.get_all_descendants(updated_tree, tree.root_id)
      assert descendants == [child_id]
    end

    test "returns empty list for leaf node" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      descendants = Utils.get_all_descendants(tree, tree.root_id)
      assert descendants == []
    end

    test "returns empty list for non-existent node" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      descendants = Utils.get_all_descendants(tree, "non_existent")
      assert descendants == []
    end
  end

  describe "remove_subtree/2" do
    test "removes a node and all its descendants" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      # Add a child node
      child_id = Utils.generate_node_id()
      child_node = %{
        id: child_id,
        task: {:move, ["player", "room1"]},
        parent_id: tree.root_id,
        children_ids: [],
        state: state,
        visited: false,
        expanded: false,
        method_tried: nil,
        blacklisted_methods: [],
        is_primitive: false,
        is_durative: false
      }

      updated_tree = %{tree | nodes: Map.put(tree.nodes, child_id, child_node)}
      updated_tree = %{updated_tree | nodes: Map.update!(updated_tree.nodes, tree.root_id, fn root ->
        %{root | children_ids: [child_id]}
      end)}

      # Remove the subtree
      cleaned_tree = Utils.remove_subtree(updated_tree, child_id)

      refute Map.has_key?(cleaned_tree.nodes, child_id)
      # Root should still exist
      assert Map.has_key?(cleaned_tree.nodes, tree.root_id)
    end
  end

  describe "get_path_to_node/2" do
    test "returns path from root to target node" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      # Add a child node
      child_id = Utils.generate_node_id()
      child_node = %{
        id: child_id,
        task: {:move, ["player", "room1"]},
        parent_id: tree.root_id,
        children_ids: [],
        state: state,
        visited: false,
        expanded: false,
        method_tried: nil,
        blacklisted_methods: [],
        is_primitive: false,
        is_durative: false
      }

      updated_tree = %{tree | nodes: Map.put(tree.nodes, child_id, child_node)}
      updated_tree = %{updated_tree | nodes: Map.update!(updated_tree.nodes, tree.root_id, fn root ->
        %{root | children_ids: [child_id]}
      end)}

      path = Utils.get_path_to_node(updated_tree, child_id)
      assert path == [tree.root_id, child_id]
    end

    test "returns empty list for non-existent target" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      path = Utils.get_path_to_node(tree, "non_existent")
      assert path == []
    end
  end

  describe "is_complete?/1" do
    test "returns true for tree with only primitive nodes" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      # Make root primitive
      updated_tree = %{tree | nodes: Map.update!(tree.nodes, tree.root_id, fn root ->
        %{root | is_primitive: true}
      end)}

      assert Utils.is_complete?(updated_tree)
    end

    test "returns false for tree with unexpanded task nodes" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      refute Utils.is_complete?(tree)
    end
  end

  describe "get_leaf_nodes/1" do
    test "returns nodes with no children" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      leaves = Utils.get_leaf_nodes(tree)
      assert leaves == [tree.root_id]
    end
  end

  describe "count_nodes_by_type/1" do
    test "counts different types of nodes" do
      todos = [{:goal, "location", "player", "room1"}]
      state = AriaState.new()
      tree = Utils.create_initial_solution_tree(todos, state)

      counts = Utils.count_nodes_by_type(tree)
      assert counts.primitive == 0
      assert counts.task == 1  # root node
      assert counts.goal == 0
      assert counts.multigoal == 0
    end
  end
end
