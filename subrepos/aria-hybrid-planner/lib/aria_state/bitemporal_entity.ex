# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState.BitemporalEntity do
  @moduledoc """
  Ecto schema for storing bitemporal entities in 6NF format.

  Represents entity declarations: ENTITY entity_name entity_id
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "entities" do
    field :entity_name, :string
    field :entity_id, :binary_id

    # Bitemporal timestamps
    field :valid_from, :utc_datetime_usec
    field :valid_to, :utc_datetime_usec
    field :recorded_at, :utc_datetime_usec
    field :recorded_to, :utc_datetime_usec

    timestamps()
  end

  def changeset(entity, attrs) do
    entity
    |> Ecto.Changeset.cast(attrs, [
      :entity_name, :entity_id,
      :valid_from, :valid_to, :recorded_at, :recorded_to
    ])
    |> Ecto.Changeset.validate_required([:entity_name, :entity_id, :recorded_at])
  end
end
