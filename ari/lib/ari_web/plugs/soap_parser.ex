defmodule AriWeb.Plugs.SOAPParser do
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    cleaned_body = clean_body(body)

    conn
    |> put_private(:cleaned_body, cleaned_body)
    |> assign(:body_params, cleaned_body)
  end

  defp clean_body(body) do
    body
    |> String.replace(~r/\r\n|\r|\n/, "")
    |> String.trim()
  end
end