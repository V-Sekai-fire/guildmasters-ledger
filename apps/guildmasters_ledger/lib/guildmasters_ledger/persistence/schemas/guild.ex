defmodule GuildmastersLedger.Persistence.Schemas.Guild do
  @moduledoc """
  Guild schema for persistence layer

  Stores guild-specific facts like gold reserves.
  Maps to predicates like "guild_gold".
  """

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "guilds" do
    field :guild_id, :string
    field :gold, :integer

    timestamps(type: :utc_datetime_usec)
  end

  import Ecto.Changeset

  @doc false
  def changeset(guild, attrs) do
    guild
    |> cast(attrs, [:guild_id, :gold])
    |> validate_required([:guild_id])
    |> unique_constraint(:guild_id)
  end
end
