defmodule AriWeb.Plugs.SkipCSRFProtection do
  import Plug.Conn

  @behaviour Plug

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_private(:plug_skip_csrf_protection, true)
  end
end