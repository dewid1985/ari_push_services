defmodule Ari.Auth do
  use Joken.Config

  @impl true
  def token_config do
    default_claims(skip: [:aud, :iss, :jti, :nbf], default_exp: config(:jwt_ttl_seconds))
  end

  def generate_jwt(user) do
    generate_and_sign!(%{"user_id" => user.id}, signer())
  end

  def verify_jwt(token) do
    case verify_and_validate(token, signer()) do
      {:ok, claims} -> {:ok, claims}
      {:error, _reason} -> {:error, :invalid_token}
    end
  end

  def cookie_name, do: config(:cookie_name)

  def cookie_options do
    [
      http_only: true,
      same_site: config(:cookie_same_site),
      max_age: config(:cookie_max_age),
      secure: config(:cookie_secure)
    ]
  end

  defp signer do
    Joken.Signer.create("HS256", config(:jwt_secret_key))
  end

  defp config(key) do
    :ari
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
