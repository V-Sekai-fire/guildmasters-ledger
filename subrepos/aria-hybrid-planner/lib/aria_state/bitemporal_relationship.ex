# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState.BitemporalRelationship do
  @moduledoc """
  Ecto schema for storing bitemporal relationships in 6NF format.

  Represents relationship declarations: RELATIONSHIP name relationship_id entity_name entity_id entity_name entity_id
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "relationships" do
    field :name, :string
    field :relationship_id, :binary_id

    # Source entity
    field :source_entity_name, :string
    field :source_entity_id, :binary_id

    # Target entity
    field :target_entity_name, :string
    field :target_entity_id, :binary_id

    # Bitemporal timestamps
    field :valid_from, :utc_datetime_usec
    field :valid_to, :utc_datetime_usec
    field :recorded_at, :utc_datetime_usec
    field :recorded_to, :utc_datetime_usec

    timestamps()
  end

  def changeset(relationship, attrs) do
    relationship
    |> Ecto.Changeset.cast(attrs, [
      :name, :relationship_id,
      :source_entity_name, :source_entity_id,
      :target_entity_name, :target_entity_id,
      :valid_from, :valid_to, :recorded_at, :recorded_to
    ])
    |> Ecto.Changeset.validate_required([
      :name, :relationship_id,
      :source_entity_name, :source_entity_id,
      :target_entity_name, :target_entity_id,
      :recorded_at
    ])
  end
end
