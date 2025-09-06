defmodule AriaEngineCore.Domain.BehaviourImplTest do
  use ExUnit.Case, async: true

  alias AriaEngineCore.Domain.BehaviourImpl

  describe "task_methods/1" do
    test "returns empty map when domain has no task_methods" do
      domain = %{}
      assert BehaviourImpl.task_methods(domain) == %{}
    end

    test "returns task_methods when present in domain" do
      task_methods = %{"method1" => :function1, "method2" => :function2}
      domain = %{task_methods: task_methods}
      assert BehaviourImpl.task_methods(domain) == task_methods
    end
  end

  describe "unigoal_methods/1" do
    test "returns empty map when domain has no unigoal_methods" do
      domain = %{}
      assert BehaviourImpl.unigoal_methods(domain) == %{}
    end

    test "returns unigoal_methods when present in domain" do
      unigoal_methods = %{"goal1" => :function1, "goal2" => :function2}
      domain = %{unigoal_methods: unigoal_methods}
      assert BehaviourImpl.unigoal_methods(domain) == unigoal_methods
    end
  end

  describe "durative_actions/1" do
    test "returns empty map when domain has no durative_actions" do
      domain = %{}
      assert BehaviourImpl.durative_actions(domain) == %{}
    end

    test "returns durative_actions when present in domain" do
      durative_actions = %{"action1" => :function1, "action2" => :function2}
      domain = %{durative_actions: durative_actions}
      assert BehaviourImpl.durative_actions(domain) == durative_actions
    end
  end
end
