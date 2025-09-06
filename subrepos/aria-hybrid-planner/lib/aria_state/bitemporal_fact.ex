# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState.BitemporalFact do
  @moduledoc """
  Ecto schema for storing aria_state facts in bitemporal 6NF format.

  Maps aria_state predicate-subject-fact triples to PostgreSQL with
  complete bitemporal audit trail support.
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "facts" do
    # AriaState triple components
    field :predicate, :string
    field :subject, :string
    field :fact_value, :map  # Stores complex Elixir terms as JSON

    # Bitemporal timestamps (6NF compliance)
    field :valid_from, :utc_datetime_usec
    field :valid_to, :utc_datetime_usec
    field :recorded_at, :utc_datetime_usec
    field :recorded_to, :utc_datetime_usec

    timestamps()
  end

  @doc "Changeset for creating/updating bitemporal facts"
  def changeset(fact, attrs) do
    fact
    |> Ecto.Changeset.cast(attrs, [
      :predicate, :subject, :fact_value,
      :valid_from, :valid_to, :recorded_at, :recorded_to
    ])
    |> Ecto.Changeset.validate_required([:predicate, :subject, :fact_value, :recorded_at])
    |> validate_bitemporal_constraints()
  end

  # Validate bitemporal constraints
  defp validate_bitemporal_constraints(changeset) do
    changeset
    |> Ecto.Changeset.validate_change(:valid_from, fn :valid_from, valid_from ->
      if valid_from && changeset.changes[:valid_to] do
        if DateTime.compare(valid_from, changeset.changes[:valid_to]) != :lt do
          [valid_from: "must be before valid_to"]
        else
          []
        end
      else
        []
      end
    end)
    |> Ecto.Changeset.validate_change(:recorded_at, fn :recorded_at, recorded_at ->
      if recorded_at && changeset.changes[:recorded_to] do
        if DateTime.compare(recorded_at, changeset.changes[:recorded_to]) != :lt do
          [recorded_at: "must be before recorded_to"]
        else
          []
        end
      else
        []
      end
    end)
  end
end
