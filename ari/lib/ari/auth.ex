defmodule Ari.Auth do
  alias Joken

  def generate_jwt(user) do
    Joken.generate_and_sign!(%{"user_id" => user.id}, %{"alg" => "HS256"})
  end

  def verify_jwt(token) do
    case Joken.verify_and_validate(token) do
      {:ok, claims} -> {:ok, claims}
      {:error, _} -> {:error, :invalid_token}
    end
  end
end
