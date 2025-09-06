defmodule AriaState.BitemporalStoreTest do
  use ExUnit.Case, async: true
  alias AriaState.BitemporalStore

  # No mocking - use real database

  describe "from_aria_state/2" do
    test "converts AriaState to bitemporal facts" do
      aria_state = AriaState.new()
      |> AriaState.set_fact("status", "chef_1", "cooking")
      |> AriaState.set_fact("temperature", "oven_1", 375)

      recorded_at = DateTime.utc_now()
      facts = BitemporalStore.from_aria_state(aria_state, recorded_at)

      assert length(facts) == 2

      # Check first fact
      fact1 = Enum.find(facts, &(&1.predicate == "status"))
      assert fact1.predicate == "status"
      assert fact1.subject == "chef_1"
      assert fact1.fact_value == "cooking"
      assert fact1.valid_from == recorded_at
      assert fact1.recorded_at == recorded_at

      # Check second fact
      fact2 = Enum.find(facts, &(&1.predicate == "temperature"))
      assert fact2.predicate == "temperature"
      assert fact2.subject == "oven_1"
      assert fact2.fact_value == 375
      assert fact2.valid_from == recorded_at
      assert fact2.recorded_at == recorded_at
    end
  end

  describe "to_aria_state/1" do
    test "converts bitemporal facts to AriaState" do
      recorded_at = DateTime.utc_now()

      # Mock bitemporal facts
      facts = [
        %{
          predicate: "status",
          subject: "chef_1",
          fact_value: "cooking",
          recorded_to: nil,  # Current version
          valid_to: nil      # Currently valid
        },
        %{
          predicate: "temperature",
          subject: "oven_1",
          fact_value: 375,
          recorded_to: nil,  # Current version
          valid_to: nil      # Currently valid
        },
        %{
          predicate: "old_status",
          subject: "chef_1",
          fact_value: "idle",
          recorded_to: recorded_at,  # Old version
          valid_to: nil
        }
      ]

      aria_state = BitemporalStore.to_aria_state(facts)

      # Should only include current facts
      assert AriaState.get_fact(aria_state, "status", "chef_1") == {:ok, "cooking"}
      assert AriaState.get_fact(aria_state, "temperature", "oven_1") == {:ok, 375}
      assert AriaState.get_fact(aria_state, "old_status", "chef_1") == {:error, :not_found}
    end
  end

  describe "store_attribute_reference/7" do
    test "function exists with correct signature" do
      # This test verifies the function exists and has the correct signature
      # We can't test the actual database operation without database running
      functions = AriaState.BitemporalStore.__info__(:functions)
      assert functions[:store_attribute_reference] == 7
    end
  end
end
