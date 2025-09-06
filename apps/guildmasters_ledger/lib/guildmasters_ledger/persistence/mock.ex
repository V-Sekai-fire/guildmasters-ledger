# Temporarily disabled for benchmarking
# defmodule GuildmastersLedger.Persistence.Mock do
#   @moduledoc """
#   Mox mock implementation of the persistence layer for testing
#
#   This module provides a mock implementation that can be used with Mox
#   for testing components that depend on the persistence layer.
#   """
#
#   @behaviour GuildmastersLedger.Persistence
#
#   import Mox
#
#   @doc """
#   Retrieves a fact value for the given predicate and subject.
#   """
#   @impl true
#   def get_fact(predicate, subject) do
#     Mox.expect(__MODULE__, :get_fact, fn ^predicate, ^subject -> nil end)
#     nil
#   end
#
#   @doc """
#   Sets a fact value for the given predicate and subject.
#   """
#   @impl true
#   def set_fact(predicate, subject, value) do
#     Mox.expect(__MODULE__, :set_fact, fn ^predicate, ^subject, ^value -> :ok end)
#     :ok
#   end
#
#   @doc """
#   Initializes the mock persistence layer.
#   """
#   @impl true
#   def init do
#     :ok
#   end
#
#   @doc """
#   Cleans up the mock persistence layer.
#   """
#   @impl true
#   def cleanup do
#     :ok
#   end
# end
