defmodule Ari.Schemas.Shared.FetchData do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    # Field definitions for FetchData schema
    field :hotel_code, :string
    field :customer_code, :string
    embeds_one :pagination, Ari.Schemas.Shared.Pagination
  end

  @doc """
  Creates a changeset for FetchData by casting attributes and embedding pagination.
  Validates that :hotel_code is present and returns a custom error message if it is missing.
  """
  def changeset(fetch_data, attrs) do
    fetch_data
    |> cast(attrs, [:hotel_code, :customer_code])
    |> validate_required([:hotel_code], message: "hotel_code is required")
    |> cast_embed(:pagination)
  end
end