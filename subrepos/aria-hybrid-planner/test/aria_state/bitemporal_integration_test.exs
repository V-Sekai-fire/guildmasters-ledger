defmodule AriaState.BitemporalIntegrationTest do
  use ExUnit.Case, async: true
  alias AriaState.{BitemporalStore, BitemporalFact, BitemporalEntity, BitemporalReference}

  describe "complete bitemporal 6NF workflow" do
    test "bank-customer relationship example" do
      now = DateTime.utc_now()

      # 1. Test AriaState to bitemporal facts conversion
      aria_state = AriaState.new()
      |> AriaState.set_fact("status", "chef_1", "cooking")
      |> AriaState.set_fact("temperature", "oven_1", 375)

      facts = BitemporalStore.from_aria_state(aria_state, now)
      assert length(facts) == 2

      # Verify fact structure
      status_fact = Enum.find(facts, &(&1.predicate == "status"))
      assert status_fact.subject == "chef_1"
      assert status_fact.fact_value == "cooking"
      assert status_fact.valid_from == now
      assert status_fact.recorded_at == now
      assert status_fact.valid_to == nil
      assert status_fact.recorded_to == nil

      # 2. Test bitemporal facts to AriaState conversion
      reconstructed_state = BitemporalStore.to_aria_state(facts)
      assert AriaState.get_fact(reconstructed_state, "status", "chef_1") == {:ok, "cooking"}
      assert AriaState.get_fact(reconstructed_state, "temperature", "oven_1") == {:ok, 375}

      # 3. Test schema validations
      valid_attrs = %{
        predicate: "location",
        subject: "player",
        fact_value: %{"value" => "kitchen"},
        recorded_at: now
      }

      changeset = BitemporalFact.changeset(%BitemporalFact{}, valid_attrs)
      assert changeset.valid?

      # 4. Test entity schema
      entity_attrs = %{
        entity_name: "bank",
        entity_id: <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16>>,
        recorded_at: now
      }

      entity_changeset = BitemporalEntity.changeset(%BitemporalEntity{}, entity_attrs)
      assert entity_changeset.valid?

      # 5. Test reference schema
      reference_attrs = %{
        name: "country_code",
        reference_id: <<17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32>>,
        value: "US",
        recorded_at: now
      }

      reference_changeset = BitemporalReference.changeset(%BitemporalReference{}, reference_attrs)
      assert reference_changeset.valid?
    end

    test "bitemporal constraints validation" do
      now = DateTime.utc_now()
      past = DateTime.add(now, -3600, :second) # 1 hour ago

      # Test invalid valid_from > valid_to
      invalid_attrs = %{
        predicate: "status",
        subject: "chef_1",
        fact_value: %{"value" => "cooking"},
        recorded_at: now,
        valid_from: now,
        valid_to: past  # Invalid: valid_to before valid_from
      }

      changeset = BitemporalFact.changeset(%BitemporalFact{}, invalid_attrs)
      refute changeset.valid?
      assert %{valid_from: ["must be before valid_to"]} = errors_on(changeset)
    end

    test "time travel functionality simulation" do
      past_time = DateTime.add(DateTime.utc_now(), -86400, :second) # 1 day ago
      now = DateTime.utc_now()

      # Simulate facts at different times
      old_facts = [
        %{predicate: "status", subject: "chef_1", fact_value: "idle",
          valid_from: past_time, recorded_at: past_time, recorded_to: nil, valid_to: nil}
      ]

      current_facts = [
        %{predicate: "status", subject: "chef_1", fact_value: "cooking",
          valid_from: now, recorded_at: now, recorded_to: nil, valid_to: nil}
      ]

      # At past time, should see old value
      past_state = BitemporalStore.to_aria_state(old_facts)
      assert AriaState.get_fact(past_state, "status", "chef_1") == {:ok, "idle"}

      # At current time, should see current value
      current_state = BitemporalStore.to_aria_state(current_facts)
      assert AriaState.get_fact(current_state, "status", "chef_1") == {:ok, "cooking"}
    end
  end

  describe "6NF record type support" do
    test "all record types are supported" do
      _now = DateTime.utc_now()

      # Test that all the main functions exist and have correct signatures
      # (We can't test actual database operations without database running)

      # Entity support
      assert function_exported?(BitemporalStore, :store_entity, 5)
      assert function_exported?(BitemporalStore, :get_current_entity, 2)

      # Reference support
      assert function_exported?(BitemporalStore, :store_reference, 6)
      assert function_exported?(BitemporalStore, :get_current_reference, 2)

      # Structure support
      assert function_exported?(BitemporalStore, :store_structure, 7)
      assert function_exported?(BitemporalStore, :get_current_structure, 2)

      # Relationship support
      assert function_exported?(BitemporalStore, :store_relationship, 9)
      assert function_exported?(BitemporalStore, :get_current_relationships, 2)
      assert function_exported?(BitemporalStore, :get_current_relationship, 2)

      # Attribute support
      assert function_exported?(BitemporalStore, :store_attribute_reference, 7)
      assert function_exported?(BitemporalStore, :store_attribute_of_structure, 6)
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
