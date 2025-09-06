defmodule GuildmastersLedger.Persistence.Schemas.Entity do
  @moduledoc """
  Entity schema for persistence layer

  Stores general entity facts like type, capabilities, and status.
  Maps to predicates like "type", "capabilities", "status".
  """

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "entities" do
    field :entity_id, :string
    field :type, :string
    field :capabilities, {:array, :string}
    field :status, :string

    timestamps(type: :utc_datetime_usec)
  end

  import Ecto.Changeset

  @doc false
  def changeset(entity, attrs) do
    entity
    |> cast(attrs, [:entity_id, :type, :capabilities, :status])
    |> validate_required([:entity_id])
    |> unique_constraint(:entity_id)
  end
end
