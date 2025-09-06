defmodule GuildmastersLedger.Repo.Migrations.CreatePersistenceTables do
  @moduledoc """
  Migration to create traditional Ecto schemas for persistence layer

  Creates tables for heroes, quests, guilds, and entities with binary IDs
  and UTC datetime timestamps with microsecond precision.
  """

  use Ecto.Migration

  def change do
    # Create heroes table
    create table(:heroes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :hero_id, :string, null: false
      add :status, :string
      add :location, :string
      add :capabilities, {:array, :string}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:heroes, [:hero_id])

    # Create quests table
    create table(:quests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :quest_id, :string, null: false
      add :status, :string
      add :accepted_at, :utc_datetime_usec
      add :location, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:quests, [:quest_id])

    # Create guilds table
    create table(:guilds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :guild_id, :string, null: false
      add :gold, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:guilds, [:guild_id])

    # Create entities table
    create table(:entities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entity_id, :string, null: false
      add :type, :string
      add :capabilities, {:array, :string}
      add :status, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:entities, [:entity_id])
  end
end
