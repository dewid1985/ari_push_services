defmodule AriWeb.SoapController do
  use AriWeb, :controller

  def public(conn, _params) do
    render_wsdl(conn, "public.wsdl.eex")
  end

  def private(conn, _params) do
    render_wsdl(conn, "private.wsdl.eex")
  end

  defp render_wsdl(conn, template) do
    body =
      :ari
      |> :code.priv_dir()
      |> Path.join("static/#{template}")
      |> EEx.eval_file(base_url: base_url(conn))

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, body)
  end

  defp base_url(conn) do
    scheme = Atom.to_string(conn.scheme)
    port = port_segment(scheme, conn.port)

    "#{scheme}://#{conn.host}#{port}"
  end

  defp port_segment("http", 80), do: ""
  defp port_segment("https", 443), do: ""
  defp port_segment(_scheme, port), do: ":#{port}"
end
