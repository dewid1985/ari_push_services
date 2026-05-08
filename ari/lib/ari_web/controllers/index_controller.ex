defmodule AriWeb.IndexController do
  use AriWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
