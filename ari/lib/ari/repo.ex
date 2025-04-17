defmodule Ari.Repo do
  use Ecto.Repo,
    otp_app: :ari,
    adapter: Ecto.Adapters.Postgres
end
