defmodule GuildmastersLedger.Persistence.Repo do
  @moduledoc """
  Ecto repository for the persistence layer

  This repo handles database operations for the traditional schemas.
  """

  use Ecto.Repo,
    otp_app: :guildmasters_ledger,
    adapter: Ecto.Adapters.Postgres
end
