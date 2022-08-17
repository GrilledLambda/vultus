defmodule VultusWeb.PageController do
  use VultusWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
