defmodule AriWeb.SessionController do
  use AriWeb, :controller

  alias Ari.Accounts
  alias Ari.Auth

  def new(conn, params) do
    render(conn, :new,
      error: nil,
      info: info_message(Map.get(params, "reason")),
      next: safe_next_path(Map.get(params, "next"))
    )
  end

  def create(conn, %{"email" => email, "password" => password} = params) do
    next_path = safe_next_path(Map.get(params, "next"))

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        token = Auth.generate_jwt(user)

        conn
        |> put_resp_cookie(Auth.cookie_name(), token, Auth.cookie_options())
        |> redirect(to: next_path)

      {:error, :unauthorized} ->
        conn
        |> put_status(:unauthorized)
        |> render(:new, error: "Invalid email or password", info: nil, next: next_path)
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_resp_cookie(Auth.cookie_name(), same_site: Auth.cookie_options()[:same_site])
    |> redirect(to: "/login")
  end

  def show(conn, _params) do
    user = conn.assigns.current_user

    json(conn, %{
      authenticated: true,
      user: %{
        id: user.id,
        email: user.email,
        customer_code: user.customer_code
      }
    })
  end

  defp safe_next_path(nil), do: "/viewer/index.html"
  defp safe_next_path(""), do: "/viewer/index.html"

  defp safe_next_path(path) when is_binary(path) do
    if String.starts_with?(path, "/") and not String.starts_with?(path, "//") do
      path
    else
      "/viewer/index.html"
    end
  end

  defp info_message("expired"), do: "Your session has expired. Please sign in again."
  defp info_message("auth_required"), do: "You need to sign in to access this page."
  defp info_message(_reason), do: nil
end
