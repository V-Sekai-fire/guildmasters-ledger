defmodule GuildmastersLedger.Persistence.Schemas.Quest do
  @moduledoc """
  Quest schema for persistence layer

  Stores quest-specific facts like status, accepted_at, and location.
  Maps to predicates like "quest_status", "quest_accepted_at".
  """

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "quests" do
    field :quest_id, :string
    field :status, :string
    field :accepted_at, :utc_datetime_usec
    field :location, :string

    timestamps(type: :utc_datetime_usec)
  end

  import Ecto.Changeset

  @doc false
  def changeset(quest, attrs) do
    quest
    |> cast(attrs, [:quest_id, :status, :accepted_at, :location])
    |> validate_required([:quest_id])
    |> unique_constraint(:quest_id)
  end
end
