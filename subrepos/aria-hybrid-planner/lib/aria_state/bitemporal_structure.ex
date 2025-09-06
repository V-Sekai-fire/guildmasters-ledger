# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState.BitemporalStructure do
  @moduledoc """
  Ecto schema for storing bitemporal structures in 6NF format.

  Represents structure declarations: STRUCT_OF entity_name entity_id name struct_id
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "structures" do
    field :entity_name, :string
    field :entity_id, :binary_id
    field :name, :string
    field :struct_id, :binary_id

    # Bitemporal timestamps
    field :valid_from, :utc_datetime_usec
    field :valid_to, :utc_datetime_usec
    field :recorded_at, :utc_datetime_usec
    field :recorded_to, :utc_datetime_usec

    timestamps()
  end

  def changeset(structure, attrs) do
    structure
    |> Ecto.Changeset.cast(attrs, [
      :entity_name, :entity_id, :name, :struct_id,
      :valid_from, :valid_to, :recorded_at, :recorded_to
    ])
    |> Ecto.Changeset.validate_required([:entity_name, :entity_id, :name, :struct_id, :recorded_at])
  end
end
