defmodule Vultuschat.Repo do
  use Ecto.Repo,
    otp_app: :vultuschat,
    adapter: Ecto.Adapters.Postgres
end
