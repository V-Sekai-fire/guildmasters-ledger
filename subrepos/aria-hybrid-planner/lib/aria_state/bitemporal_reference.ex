# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState.BitemporalReference do
  @moduledoc """
  Ecto schema for storing bitemporal references in 6NF format.

  Represents reference declarations: REFERENCE name reference_id value
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "references" do
    field :name, :string
    field :reference_id, :binary_id
    field :value, :string

    # Bitemporal timestamps
    field :valid_from, :utc_datetime_usec
    field :valid_to, :utc_datetime_usec
    field :recorded_at, :utc_datetime_usec
    field :recorded_to, :utc_datetime_usec

    timestamps()
  end

  def changeset(reference, attrs) do
    reference
    |> Ecto.Changeset.cast(attrs, [
      :name, :reference_id, :value,
      :valid_from, :valid_to, :recorded_at, :recorded_to
    ])
    |> Ecto.Changeset.validate_required([:name, :reference_id, :value, :recorded_at])
  end
end
