defmodule AriWeb.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias Ari.Auth
  alias Ari.Repo
  alias Ari.Schemas.Users.User

  @behaviour Plug

  def init(opts), do: Keyword.put_new(opts, :mode, :json)

  def call(conn, opts) do
    with {:ok, token} <- fetch_token(conn),
         {:ok, claims} <- Auth.verify_jwt(token),
         {:ok, user_id} <- fetch_user_id(claims),
         %User{} = user <- Repo.get(User, user_id) do
      assign(conn, :current_user, user)
    else
      _ ->
        handle_unauthorized(conn, opts[:mode])
    end
  end

  defp fetch_token(conn) do
    conn = fetch_cookies(conn)

    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> fetch_token_from_cookie(conn)
    end
  end

  defp fetch_token_from_cookie(conn) do
    case conn.cookies["auth_token"] do
      token when is_binary(token) and token != "" -> {:ok, token}
      _ -> {:error, :missing_token}
    end
  end

  defp fetch_user_id(%{"user_id" => user_id}) when is_integer(user_id), do: {:ok, user_id}

  defp fetch_user_id(%{"user_id" => user_id}) when is_binary(user_id) do
    case Integer.parse(user_id) do
      {parsed, ""} -> {:ok, parsed}
      _ -> {:error, :invalid_user_id}
    end
  end

  defp fetch_user_id(_claims), do: {:error, :missing_user_id}

  defp handle_unauthorized(conn, :redirect) do
    conn
    |> redirect(to: login_path(conn, "auth_required"))
    |> halt()
  end

  defp handle_unauthorized(conn, _mode) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:unauthorized, ~s({"error":"Unauthorized"}))
    |> halt()
  end

  defp login_path(conn, reason) do
    next =
      case conn.query_string do
        "" -> conn.request_path
        query -> conn.request_path <> "?" <> query
      end

    "/login?next=" <> URI.encode_www_form(next) <> "&reason=" <> URI.encode_www_form(reason)
  end
end
