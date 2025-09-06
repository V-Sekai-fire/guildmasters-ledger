# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState.BitemporalStore do
  @moduledoc """
  Integration layer between AriaState and PostgreSQL bitemporal storage.

  Provides functions to store and retrieve aria_state facts with full
  bitemporal audit trail support.
  """
  import Ecto.Query
  alias AriaState.{BitemporalFact, BitemporalEntity, BitemporalReference, BitemporalStructure, BitemporalRelationship}

  # Allow repo to be configured for testing
  @repo Application.compile_env(:aria_hybrid_planner, :repo, AriaState.Repo)

  @doc "Store an aria_state fact with bitemporal metadata"
  @spec store_fact(String.t(), String.t(), any(), DateTime.t(), DateTime.t() | nil, DateTime.t()) ::
    {:ok, BitemporalFact.t()} | {:error, Ecto.Changeset.t()}
  def store_fact(predicate, subject, fact_value, valid_from, valid_to, recorded_at) do
    attrs = %{
      predicate: predicate,
      subject: subject,
      fact_value: fact_value,
      valid_from: valid_from,
      valid_to: valid_to,
      recorded_at: recorded_at
    }

    %BitemporalFact{}
    |> BitemporalFact.changeset(attrs)
    |> @repo.insert()
  end

  @doc "Store an aria_state fact with bitemporal metadata and options"
  @spec store_fact_with_opts(String.t(), String.t(), any(), DateTime.t(), DateTime.t() | nil, DateTime.t(), keyword()) ::
    {:ok, BitemporalFact.t()} | {:error, Ecto.Changeset.t()}
  def store_fact_with_opts(predicate, subject, fact_value, valid_from, valid_to, recorded_at, opts) do
    attrs = %{
      predicate: predicate,
      subject: subject,
      fact_value: fact_value,
      valid_from: valid_from,
      valid_to: valid_to,
      recorded_at: recorded_at
    }

    %BitemporalFact{}
    |> BitemporalFact.changeset(attrs)
    |> @repo.insert(opts)
  end

  @doc "Retrieve current facts for an aria_state triple"
  @spec get_current_fact(String.t(), String.t()) :: {:ok, any()} | {:error, :not_found}
  def get_current_fact(predicate, subject) do
    query =
      from f in BitemporalFact,
      where: f.predicate == ^predicate,
      where: f.subject == ^subject,
      where: is_nil(f.recorded_to),  # Current version
      where: is_nil(f.valid_to),     # Currently valid
      select: f.fact_value

    case @repo.one(query) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  @doc "Retrieve facts valid at a specific point in time"
  @spec get_facts_at_time(String.t(), String.t(), DateTime.t()) :: [any()]
  def get_facts_at_time(predicate, subject, at_time) do
    query =
      from f in BitemporalFact,
      where: f.predicate == ^predicate,
      where: f.subject == ^subject,
      where: f.valid_from <= ^at_time,
      where: is_nil(f.valid_to) or f.valid_to > ^at_time,
      where: f.recorded_at <= ^at_time,
      where: is_nil(f.recorded_to) or f.recorded_to > ^at_time,
      select: f.fact_value

    @repo.all(query)
  end

  @doc "Convert AriaState to list of bitemporal facts"
  @spec from_aria_state(AriaState.t(), DateTime.t()) :: [map()]
  def from_aria_state(aria_state, recorded_at) do
    aria_state
    |> AriaState.to_triples()
    |> Enum.map(fn {predicate, subject, fact_value} ->
      %{
        predicate: predicate,
        subject: subject,
        fact_value: fact_value,
        valid_from: recorded_at,
        valid_to: nil,
        recorded_at: recorded_at,
        recorded_to: nil
      }
    end)
  end

  @doc "Convert bitemporal facts to AriaState"
  @spec to_aria_state([BitemporalFact.t()]) :: AriaState.t()
  def to_aria_state(facts) do
    triples =
      facts
      |> Enum.filter(&is_nil(&1.recorded_to))  # Current versions only
      |> Enum.filter(&is_nil(&1.valid_to))     # Currently valid only
      |> Enum.map(fn fact ->
        {fact.predicate, fact.subject, fact.fact_value}
      end)

    AriaState.from_triples(triples)
  end

  @doc "Get audit trail for a specific fact"
  @spec get_fact_history(String.t(), String.t()) :: [BitemporalFact.t()]
  def get_fact_history(predicate, subject) do
    query =
      from f in BitemporalFact,
      where: f.predicate == ^predicate,
      where: f.subject == ^subject,
      order_by: [desc: f.recorded_at]

    @repo.all(query)
  end

  # ============================================================================
  # ENTITY SUPPORT
  # ============================================================================

  @doc "Store a bitemporal entity"
  @spec store_entity(String.t(), String.t(), DateTime.t(), DateTime.t() | nil, DateTime.t()) ::
    {:ok, BitemporalEntity.t()} | {:error, Ecto.Changeset.t()}
  def store_entity(entity_name, entity_id, valid_from, valid_to, recorded_at) do
    attrs = %{
      entity_name: entity_name,
      entity_id: entity_id,
      valid_from: valid_from,
      valid_to: valid_to,
      recorded_at: recorded_at
    }

    %BitemporalEntity{}
    |> BitemporalEntity.changeset(attrs)
    |> @repo.insert()
  end

  @doc "Get current entity by name and ID"
  @spec get_current_entity(String.t(), String.t()) :: {:ok, BitemporalEntity.t()} | {:error, :not_found}
  def get_current_entity(entity_name, entity_id) do
    query =
      from e in BitemporalEntity,
      where: e.entity_name == ^entity_name,
      where: e.entity_id == ^entity_id,
      where: is_nil(e.recorded_to),
      where: is_nil(e.valid_to)

    case @repo.one(query) do
      nil -> {:error, :not_found}
      entity -> {:ok, entity}
    end
  end

  # ============================================================================
  # REFERENCE SUPPORT
  # ============================================================================

  @doc "Store a bitemporal reference"
  @spec store_reference(String.t(), String.t(), String.t(), DateTime.t(), DateTime.t() | nil, DateTime.t()) ::
    {:ok, BitemporalReference.t()} | {:error, Ecto.Changeset.t()}
  def store_reference(name, reference_id, value, valid_from, valid_to, recorded_at) do
    attrs = %{
      name: name,
      reference_id: reference_id,
      value: value,
      valid_from: valid_from,
      valid_to: valid_to,
      recorded_at: recorded_at
    }

    %BitemporalReference{}
    |> BitemporalReference.changeset(attrs)
    |> @repo.insert()
  end

  @doc "Get current reference by name and ID"
  @spec get_current_reference(String.t(), String.t()) :: {:ok, BitemporalReference.t()} | {:error, :not_found}
  def get_current_reference(name, reference_id) do
    query =
      from r in BitemporalReference,
      where: r.name == ^name,
      where: r.reference_id == ^reference_id,
      where: is_nil(r.recorded_to),
      where: is_nil(r.valid_to)

    case @repo.one(query) do
      nil -> {:error, :not_found}
      reference -> {:ok, reference}
    end
  end

  # ============================================================================
  # STRUCTURE SUPPORT
  # ============================================================================

  @doc "Store a bitemporal structure"
  @spec store_structure(String.t(), String.t(), String.t(), String.t(), DateTime.t(), DateTime.t() | nil, DateTime.t()) ::
    {:ok, BitemporalStructure.t()} | {:error, Ecto.Changeset.t()}
  def store_structure(entity_name, entity_id, name, struct_id, valid_from, valid_to, recorded_at) do
    attrs = %{
      entity_name: entity_name,
      entity_id: entity_id,
      name: name,
      struct_id: struct_id,
      valid_from: valid_from,
      valid_to: valid_to,
      recorded_at: recorded_at
    }

    %BitemporalStructure{}
    |> BitemporalStructure.changeset(attrs)
    |> @repo.insert()
  end

  @doc "Get current structure by entity and struct ID"
  @spec get_current_structure(String.t(), String.t()) :: {:ok, BitemporalStructure.t()} | {:error, :not_found}
  def get_current_structure(entity_name, entity_id) do
    query =
      from s in BitemporalStructure,
      where: s.entity_name == ^entity_name,
      where: s.entity_id == ^entity_id,
      where: is_nil(s.recorded_to),
      where: is_nil(s.valid_to)

    case @repo.one(query) do
      nil -> {:error, :not_found}
      structure -> {:ok, structure}
    end
  end

  # ============================================================================
  # RELATIONSHIP SUPPORT
  # ============================================================================

  @doc "Store a bitemporal relationship"
  @spec store_relationship(String.t(), String.t(), String.t(), String.t(), String.t(), String.t(), DateTime.t(), DateTime.t() | nil, DateTime.t()) ::
    {:ok, BitemporalRelationship.t()} | {:error, Ecto.Changeset.t()}
  def store_relationship(name, relationship_id, source_entity_name, source_entity_id, target_entity_name, target_entity_id, valid_from, valid_to, recorded_at) do
    attrs = %{
      name: name,
      relationship_id: relationship_id,
      source_entity_name: source_entity_name,
      source_entity_id: source_entity_id,
      target_entity_name: target_entity_name,
      target_entity_id: target_entity_id,
      valid_from: valid_from,
      valid_to: valid_to,
      recorded_at: recorded_at
    }

    %BitemporalRelationship{}
    |> BitemporalRelationship.changeset(attrs)
    |> @repo.insert()
  end

  @doc "Get current relationships by source entity"
  @spec get_current_relationships(String.t(), String.t()) :: [BitemporalRelationship.t()]
  def get_current_relationships(source_entity_name, source_entity_id) do
    query =
      from r in BitemporalRelationship,
      where: r.source_entity_name == ^source_entity_name,
      where: r.source_entity_id == ^source_entity_id,
      where: is_nil(r.recorded_to),
      where: is_nil(r.valid_to)

    @repo.all(query)
  end

  @doc "Get current relationship by ID"
  @spec get_current_relationship(String.t(), String.t()) :: {:ok, BitemporalRelationship.t()} | {:error, :not_found}
  def get_current_relationship(name, relationship_id) do
    query =
      from r in BitemporalRelationship,
      where: r.name == ^name,
      where: r.relationship_id == ^relationship_id,
      where: is_nil(r.recorded_to),
      where: is_nil(r.valid_to)

    case @repo.one(query) do
      nil -> {:error, :not_found}
      relationship -> {:ok, relationship}
    end
  end

  # ============================================================================
  # ATTRIBUTE REFERENCE SUPPORT (links facts to references)
  # ============================================================================

  @doc "Store an attribute reference (links fact to reference)"
  @spec store_attribute_reference(String.t(), String.t(), String.t(), String.t(), DateTime.t(), DateTime.t() | nil, DateTime.t()) ::
    {:ok, BitemporalFact.t()} | {:error, Ecto.Changeset.t()}
  def store_attribute_reference(_entity_name, entity_id, attribute_name, reference_id, valid_from, valid_to, recorded_at) do
    # Store as a fact with the reference_id as the value
    store_fact(attribute_name, entity_id, reference_id, valid_from, valid_to, recorded_at)
  end

  @doc "Store an attribute of a structure"
  @spec store_attribute_of_structure(String.t(), String.t(), String.t(), DateTime.t(), DateTime.t() | nil, DateTime.t()) ::
    {:ok, BitemporalFact.t()} | {:error, Ecto.Changeset.t()}
  def store_attribute_of_structure(struct_id, attribute_name, value, valid_from, valid_to, recorded_at) do
    # Store as a fact with struct_id as subject
    store_fact(attribute_name, struct_id, value, valid_from, valid_to, recorded_at)
  end
end
