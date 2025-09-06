defmodule GuildmastersLedger.Persistence.Router do
  @moduledoc """
  Predicate router for mapping HTN planning predicates to schema operations

  This module routes predicate-subject-value operations to the appropriate
  Ecto schema and field, avoiding the EAV anti-pattern while maintaining
  the planner's get_fact/set_fact API.
  """

  alias GuildmastersLedger.Persistence.Schemas.{Hero, Quest, Guild, Entity}

  @type schema_module :: module()
  @type field :: atom()
  @type routing :: {schema_module(), field(), String.t()}

  # Predicate routing table
  # Maps predicate names to {schema, field, subject_field}
  @predicate_routes %{
    # Hero predicates
    "hero_status" => {Hero, :status, :hero_id},
    "location" => {Hero, :location, :hero_id},
    "capabilities" => {Hero, :capabilities, :hero_id},

    # Quest predicates
    "quest_status" => {Quest, :status, :quest_id},
    "quest_accepted_at" => {Quest, :accepted_at, :quest_id},

    # Guild predicates
    "guild_gold" => {Guild, :gold, :guild_id},

    # Entity predicates
    "type" => {Entity, :type, :entity_id},
    "status" => {Entity, :status, :entity_id}
  }

  @doc """
  Routes a predicate to its corresponding schema and field.

  Returns {:ok, {schema, field, subject_field}} or {:error, :unknown_predicate}
  """
  @spec route(String.t()) :: {:ok, routing()} | {:error, :unknown_predicate}
  def route(predicate) do
    case Map.get(@predicate_routes, predicate) do
      nil -> {:error, :unknown_predicate}
      routing -> {:ok, routing}
    end
  end

  @doc """
  Returns all known predicates
  """
  @spec predicates() :: [String.t()]
  def predicates do
    Map.keys(@predicate_routes)
  end

  @doc """
  Checks if a predicate is known
  """
  @spec known_predicate?(String.t()) :: boolean()
  def known_predicate?(predicate) do
    Map.has_key?(@predicate_routes, predicate)
  end
end
