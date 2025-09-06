# Ecto FoundationDB Schema for Bitemporal 6NF Data Format Specification

**Version:** 1.3 (Adapted for Ecto FoundationDB)  
**Date:** 2025-09-05  
**Compatibility:** AriaState predicate-subject-fact triples  
**Original Specification:** [Alexey Zimarev](https://habr.com/en/articles/942516/)

This document defines the complete Ecto schema and migration system for storing aria_state facts in a bitemporal 6NF format using FoundationDB.

## Bitemporal 6NF Specification - Embedded Documentation

### DESIGN PRINCIPLES

1. **Database Friendly Flat Structure**: Each record is an atomic fact. No nested objects or JSON parsing is needed.

2. **6NF Compatibility**: Each record represents a single attribute of a single entity, aligning with the principles of the Sixth Normal Form.

3. **Complete Bitemporal Modeling**: Data is tracked along two independent time axes, allowing for a complete, auditable history.

4. **Immutability**: Data is never physically deleted. Changes are recorded by logically closing old records and creating new ones.

### CORE CONCEPTS: THE TWO TIMELINES

The format is built upon two distinct time dimensions, represented as half-open intervals `[start, end)`. A NULL end-date implies infinity.

#### Valid Time: The Real World Timeline
Describes when a fact is true in the real world.

- **`valid_from`**: The timestamp when the data BECAME true.
- **`valid_to`**: The timestamp when the data CEASED to be true. A NULL value means the fact is still considered valid.

#### Transaction Time: The System Timeline
Describes when a fact was known to the system, providing an audit trail.

- **`recorded_at`**: The timestamp when the data was RECORDED in the database.
- **`recorded_to`**: The timestamp when this record was SUPERSEDED by a new version (due to a correction or a new valid state). A NULL value means this is the current active record.

### AMENDED EBNF SYNTAX (v1.3)

This is the formal EBNF for the amended, fully bitemporal 6NF format. It incorporates the detailed syntax from the original specification and adds optional `VALID_TO` and `RECORDED_TO` fields for complete bitemporal modeling.

```ebnf
bitemporal_6nf      = [ version ] { record } ;
record              = entity | reference | attribute | attribute_ref | struct | attribute_of_struct | relationship | NEWLINE ;

version             = "VERSION" number NEWLINE ;
entity              = "ENTITY" entity_name entity_id NEWLINE ;
reference           = "REFERENCE" name reference_id value NEWLINE ;

attribute           = "ATTRIBUTE_OF" entity_name entity_id name value timestamp_block NEWLINE ;
attribute_ref       = "ATTRIBUTE_REF_OF" entity_name entity_id name reference_id timestamp_block NEWLINE ;
struct              = "STRUCT_OF" entity_name entity_id name struct_id timestamp_block NEWLINE ;
attribute_of_struct = "ATTRIBUTE_OF_STRUCT" struct_id name value NEWLINE ;
relationship        = "RELATIONSHIP" name relationship_id entity_name entity_id entity_name entity_id timestamp_block NEWLINE ;

timestamp_block     = "VALID_FROM" valid_from [ "VALID_TO" valid_to ] "RECORDED_AT" recorded_at [ "RECORDED_TO" recorded_to ] ;

value               = string | number | "true" | "false" ;
string              = "\"" (* any character except double quote *) "\"" ;
number              = [ "-" ] digit { digit } [ "." digit { digit } ] ;
valid_from          = iso8601 ;
valid_to            = iso8601 ;
recorded_at         = iso8601 ;
recorded_to         = iso8601 ;
iso8601             = (* e.g., "2023-01-01T12:00:00Z" *) ;

entity_name         = ( letter | "_" ) { letter | digit | "_" } ;
name                = ( letter | "_" ) { letter | digit | "_" } ;

(* UUIDs are stored as binary in the database but represented as Base32-encoded strings in text format *)
entity_id           = base32_uuid ;
reference_id        = base32_uuid ;
relationship_id     = base32_uuid ;
struct_id           = base32_uuid ;
base32_uuid         = 26 * base32_char ;
base32_char         = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
                    | "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "J" | "K"
                    | "M" | "N" | "P" | "Q" | "R" | "S" | "T" | "V" | "W" | "X" | "Y" | "Z" ;
```

### UUID STORAGE FORMAT

**Database Storage**: UUIDs are stored as binary data (`:binary_id` in Ecto/Elixir) for optimal performance and storage efficiency.

**Text Representation**: When UUIDs need to be displayed or transmitted in text format, they are encoded using Base32 encoding for human readability and URL safety.

**Example**:
- Database: `<<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16>>`
- Text: `01K3Y0690AJCRFEJ2J49X6ZECY`

This dual representation ensures efficient database operations while maintaining human-readable identifiers in text formats.

### FULL TEXT FORMAT EXAMPLE

This example demonstrates the amended 6NF text format syntax defined above.

```
# Entity Declarations
ENTITY bank "01K3Y0690AJCRFEJ2J49X6ZECY"
ENTITY customer "CUST123"
ENTITY bank "01K5B2..."

# Reference Value Declaration
REFERENCE country_code "01K3Y07Z94DGJWVMB0JG4YSDBV" "US"

# Simple Attribute (Bank Name)
ATTRIBUTE_OF bank "01K3Y0690AJCRFEJ2J49X6ZECY" bank_name "Bank Alpha" VALID_FROM 2023-01-01T00:00:00Z RECORDED_AT 2023-01-01T12:00:00Z

# Attribute Reference (Bank's Country)
ATTRIBUTE_REF_OF bank "01K3Y0690AJCRFEJ2J49X6ZECY" country_code "01K3Y07Z94DGJWVMB0JG4YSDBV" VALID_FROM 2023-01-01T00:00:00Z RECORDED_AT 2023-01-01T12:00:00Z

# Struct (Customer Address)
STRUCT_OF customer "CUST123" address "ADDR_ID_1" VALID_FROM 2024-06-01T00:00:00Z RECORDED_AT 2024-06-01T10:00:00Z
ATTRIBUTE_OF_STRUCT "ADDR_ID_1" street "123 Main St"
ATTRIBUTE_OF_STRUCT "ADDR_ID_1" city "Anytown"
ATTRIBUTE_OF_STRUCT "ADDR_ID_1" zip_code "12345"

# Relationship (Acquisition)
RELATIONSHIP subsidiary_of "REL_ID_1" bank "01K5B2..." bank "01K3Y0690AJCRFEJ2J49X6ZECY" VALID_FROM 2026-03-15T00:00:00Z RECORDED_AT 2026-03-15T17:00:00Z

# Correction of an Error (updating "Bank of Amerigo" to "Bank of America")
ATTRIBUTE_OF bank "01K3Y0..." bank_name "Bank of Amerigo" VALID_FROM 2025-09-04T00:00:00Z RECORDED_AT 2025-09-04T21:00:00Z RECORDED_TO 2025-09-04T22:00:00Z
ATTRIBUTE_OF bank "01K3Y0..." bank_name "Bank of America" VALID_FROM 2025-09-04T00:00:00Z RECORDED_AT 2025-09-04T22:00:00Z
```

## Ecto FoundationDB Schema for AriaState Compatibility

This section contains the complete Ecto schema and migration system for storing aria_state facts in FoundationDB with bitemporal support.

### ECTO SCHEMA DEFINITIONS

#### Bitemporal Facts Schema
```elixir
# lib/aria_state/bitemporal_fact.ex
defmodule AriaState.BitemporalFact do
  @moduledoc """
  Ecto schema for storing aria_state facts in bitemporal 6NF format.

  Maps aria_state predicate-subject-fact triples to FoundationDB with
  complete bitemporal audit trail support.
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "facts" do
    # AriaState triple components
    field :predicate, :string
    field :subject, :string
    field :fact_value, :map  # Stores complex Elixir terms as JSON

    # Bitemporal timestamps (6NF compliance)
    field :valid_from, :utc_datetime_usec
    field :valid_to, :utc_datetime_usec
    field :recorded_at, :utc_datetime_usec
    field :recorded_to, :utc_datetime_usec

    timestamps()
  end

  @doc "Changeset for creating/updating bitemporal facts"
  def changeset(fact, attrs) do
    fact
    |> Ecto.Changeset.cast(attrs, [
      :predicate, :subject, :fact_value,
      :valid_from, :valid_to, :recorded_at, :recorded_to
    ])
    |> Ecto.Changeset.validate_required([:predicate, :subject, :fact_value, :recorded_at])
    |> validate_bitemporal_constraints()
  end

  # Validate bitemporal constraints
  defp validate_bitemporal_constraints(changeset) do
    changeset
    |> Ecto.Changeset.validate_change(:valid_from, fn :valid_from, valid_from ->
      if valid_from && changeset.changes[:valid_to] do
        if DateTime.compare(valid_from, changeset.changes[:valid_to]) != :lt do
          [valid_from: "must be before valid_to"]
        else
          []
        end
      else
        []
      end
    end)
    |> Ecto.Changeset.validate_change(:recorded_at, fn :recorded_at, recorded_at ->
      if recorded_at && changeset.changes[:recorded_to] do
        if DateTime.compare(recorded_at, changeset.changes[:recorded_to]) != :lt do
          [recorded_at: "must be before recorded_to"]
        else
          []
        end
      else
        []
      end
    end)
  end
end
```

#### Ecto Migration for Indexes
```elixir
# priv/repo/migrations/001_create_bitemporal_schemas.exs
defmodule Aria.Repo.Migrations.CreateBitemporalFacts do
  use EctoFoundationDB.Migration

  @impl true
  def change() do
    [
      # Create indexes for efficient aria_state queries
      create index(AriaState.BitemporalFact, [:predicate]),
      create index(AriaState.BitemporalFact, [:subject]),
      create index(AriaState.BitemporalFact, [:predicate, :subject]),
      create index(AriaState.BitemporalFact, [:valid_from]),
      create index(AriaState.BitemporalFact, [:valid_to]),
      create index(AriaState.BitemporalFact, [:recorded_at]),
      create index(AriaState.BitemporalFact, [:recorded_to]),
      # Composite indexes for bitemporal queries
      create index(AriaState.BitemporalFact, [:predicate, :valid_from]),
      create index(AriaState.BitemporalFact, [:subject, :valid_from]),
      create index(AriaState.BitemporalFact, [:predicate, :subject, :valid_from])
    ]
  end
end
```

#### AriaState Integration Module
```elixir
# lib/aria_state/bitemporal_store.ex
defmodule AriaState.BitemporalStore do
  @moduledoc """
  Integration layer between AriaState and FoundationDB bitemporal storage.

  Provides functions to store and retrieve aria_state facts with full
  bitemporal audit trail support.
  """
  import Ecto.Query
  alias AriaState.{BitemporalFact, Repo}

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
    |> Repo.insert()
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

    case Repo.one(query) do
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

    Repo.all(query)
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
        recorded_at: recorded_at
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

    Repo.all(query)
  end
end
```

### Complete 6NF Example Usage

```elixir
# Example: Bank-Customer Relationship System
now = DateTime.utc_now()

# 1. Store Entities
{:ok, _bank} = AriaState.BitemporalStore.store_entity("bank", "01K3Y0690AJCRFEJ2J49X6ZECY", now, nil, now)
{:ok, _customer} = AriaState.BitemporalStore.store_entity("customer", "CUST123", now, nil, now)

# 2. Store References
{:ok, _country} = AriaState.BitemporalStore.store_reference("country_code", "01K3Y07Z94DGJWVMB0JG4YSDBV", "US", now, nil, now)

# 3. Store Facts (AriaState integration)
aria_state = AriaState.new()
|> AriaState.set_fact("status", "chef_1", "cooking")
|> AriaState.set_fact("temperature", "oven_1", 375)

facts = AriaState.BitemporalStore.from_aria_state(aria_state, now)
Enum.each(facts, fn fact_attrs ->
  {:ok, _fact} = AriaState.BitemporalStore.store_fact(
    fact_attrs.predicate,
    fact_attrs.subject,
    fact_attrs.fact_value,
    fact_attrs.valid_from,
    fact_attrs.valid_to,
    fact_attrs.recorded_at
  )
end)

# 4. Store Attribute References
{:ok, _bank_country} = AriaState.BitemporalStore.store_attribute_reference(
  "bank", "01K3Y0690AJCRFEJ2J49X6ZECY", "country_code", "01K3Y07Z94DGJWVMB0JG4YSDBV", now, nil, now
)

# 5. Store Structures
{:ok, _address} = AriaState.BitemporalStore.store_structure(
  "customer", "CUST123", "address", "ADDR_ID_1", now, nil, now
)

# 6. Store Attributes of Structures
{:ok, _street} = AriaState.BitemporalStore.store_attribute_of_structure(
  "ADDR_ID_1", "street", "123 Main St", now, nil, now
)
{:ok, _city} = AriaState.BitemporalStore.store_attribute_of_structure(
  "ADDR_ID_1", "city", "Anytown", now, nil, now
)

# 7. Store Relationships
{:ok, _relationship} = AriaState.BitemporalStore.store_relationship(
  "subsidiary_of", "REL_ID_1",
  "bank", "01K5B2...",
  "bank", "01K3Y0690AJCRFEJ2J49X6ZECY",
  now, nil, now
)

# Query Examples
{:ok, chef_status} = AriaState.BitemporalStore.get_current_fact("status", "chef_1")
{:ok, bank_entity} = AriaState.BitemporalStore.get_current_entity("bank", "01K3Y0690AJCRFEJ2J49X6ZECY")
{:ok, country_ref} = AriaState.BitemporalStore.get_current_reference("country_code", "01K3Y07Z94DGJWVMB0JG4YSDBV")
relationships = AriaState.BitemporalStore.get_current_relationships("bank", "01K5B2...")

# Time Travel Query
past_facts = AriaState.BitemporalStore.get_facts_at_time("status", "chef_1", ~U[2025-09-04 12:00:00Z])

# Reconstruct AriaState from stored facts
stored_facts = Repo.all(AriaState.BitemporalFact)
reconstructed_state = AriaState.BitemporalStore.to_aria_state(stored_facts)
