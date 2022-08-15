defmodule VultuschatWeb.PageController do
  use VultuschatWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
