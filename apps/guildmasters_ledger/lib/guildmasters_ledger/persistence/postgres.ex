defmodule GuildmastersLedger.Persistence.Postgres do
  @moduledoc """
  PostgreSQL implementation of the persistence layer

  Uses traditional Ecto schemas with predicate routing to maintain
  the HTN planning system's get_fact/set_fact API.
  """

  @behaviour GuildmastersLedger.Persistence

  alias GuildmastersLedger.Persistence.{Router, Repo}
  alias GuildmastersLedger.Persistence.Schemas.{Hero, Quest, Guild, Entity}

  @doc """
  Retrieves a fact value for the given predicate and subject.
  """
  @impl true
  def get_fact(predicate, subject) do
    case Router.route(predicate) do
      {:ok, {schema, field, subject_field}} ->
        get_fact_from_schema(schema, field, subject_field, subject)
      {:error, :unknown_predicate} ->
        nil
    end
  end

  @doc """
  Sets a fact value for the given predicate and subject.
  """
  @impl true
  def set_fact(predicate, subject, value) do
    case Router.route(predicate) do
      {:ok, {schema, field, subject_field}} ->
        set_fact_in_schema(schema, field, subject_field, subject, value)
      {:error, :unknown_predicate} ->
        {:error, :unknown_predicate}
    end
  end

  @doc """
  Initializes the PostgreSQL persistence layer.
  """
  @impl true
  def init do
    # TODO: Initialize Ecto repo, run migrations, etc.
    :ok
  end

  @doc """
  Cleans up the PostgreSQL persistence layer.
  """
  @impl true
  def cleanup do
    # TODO: Close connections, etc.
    :ok
  end

  # Private functions

  defp get_fact_from_schema(schema, field, subject_field, subject) do
    import Ecto.Query

    query = from record in schema,
            where: field(record, ^subject_field) == ^subject,
            select: field(record, ^field)

    case Repo.one(query) do
      nil -> nil
      value -> value
    end
  end

  defp set_fact_in_schema(schema, field, subject_field, subject, value) do
    import Ecto.Query

    # Try to find existing record
    query = from record in schema,
            where: field(record, ^subject_field) == ^subject

    case Repo.one(query) do
      nil ->
        # Create new record
        changeset = create_changeset(schema, subject_field, subject, field, value)
        case Repo.insert(changeset) do
          {:ok, _record} -> :ok
          {:error, changeset} -> {:error, changeset.errors}
        end
      existing_record ->
        # Update existing record
        changeset = update_changeset(existing_record, field, value)
        case Repo.update(changeset) do
          {:ok, _record} -> :ok
          {:error, changeset} -> {:error, changeset.errors}
        end
    end
  end

  # Helper functions for creating changesets

  defp create_changeset(Hero, :hero_id, subject, field, value) do
    attrs = Map.put(%{hero_id: subject}, field, value)
    Hero.changeset(%Hero{}, attrs)
  end

  defp create_changeset(Quest, :quest_id, subject, field, value) do
    attrs = Map.put(%{quest_id: subject}, field, value)
    Quest.changeset(%Quest{}, attrs)
  end

  defp create_changeset(Guild, :guild_id, subject, field, value) do
    attrs = Map.put(%{guild_id: subject}, field, value)
    Guild.changeset(%Guild{}, attrs)
  end

  defp create_changeset(Entity, :entity_id, subject, field, value) do
    attrs = Map.put(%{entity_id: subject}, field, value)
    Entity.changeset(%Entity{}, attrs)
  end

  defp update_changeset(record, field, value) do
    attrs = %{field => value}
    record.__struct__.changeset(record, attrs)
  end
end
