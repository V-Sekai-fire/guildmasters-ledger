defmodule GuildmastersLedger.Persistence.Schemas.Hero do
  @moduledoc """
  Hero schema for persistence layer

  Stores hero-specific facts like status, location, and capabilities.
  Maps to predicates like "hero_status", "location", "capabilities".
  """

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "heroes" do
    field :hero_id, :string
    field :status, :string
    field :location, :string
    field :capabilities, {:array, :string}

    timestamps(type: :utc_datetime_usec)
  end

  import Ecto.Changeset

  @doc false
  def changeset(hero, attrs) do
    hero
    |> cast(attrs, [:hero_id, :status, :location, :capabilities])
    |> validate_required([:hero_id])
    |> unique_constraint(:hero_id)
  end
end
