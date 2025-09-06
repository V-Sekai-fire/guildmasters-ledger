defmodule AriaState.BitemporalFactTest do
  use ExUnit.Case, async: true
  alias AriaState.BitemporalFact

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{
        predicate: "status",
        subject: "chef_1",
        fact_value: %{"value" => "cooking"},
        recorded_at: DateTime.utc_now()
      }

      changeset = BitemporalFact.changeset(%BitemporalFact{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset without required fields" do
      changeset = BitemporalFact.changeset(%BitemporalFact{}, %{})
      refute changeset.valid?

      assert %{predicate: ["can't be blank"]} = errors_on(changeset)
      assert %{subject: ["can't be blank"]} = errors_on(changeset)
      assert %{fact_value: ["can't be blank"]} = errors_on(changeset)
      assert %{recorded_at: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates bitemporal constraints" do
      valid_from = DateTime.utc_now()
      valid_to = DateTime.add(valid_from, -3600, :second) # Before valid_from

      attrs = %{
        predicate: "status",
        subject: "chef_1",
        fact_value: %{"value" => "cooking"},
        recorded_at: DateTime.utc_now(),
        valid_from: valid_from,
        valid_to: valid_to
      }

      changeset = BitemporalFact.changeset(%BitemporalFact{}, attrs)
      refute changeset.valid?
      assert %{valid_from: ["must be before valid_to"]} = errors_on(changeset)
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
