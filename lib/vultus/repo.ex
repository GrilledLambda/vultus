defmodule Vultus.Repo do
  use Ecto.Repo,
    otp_app: :vultus,
    adapter: Ecto.Adapters.Postgres
end
