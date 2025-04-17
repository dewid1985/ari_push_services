defmodule AriWeb.Form.DataFetchForm do
  use Ecto.Schema
  alias Ari.Schemas.Rate.GetRates

  def changeset(%GetRates{} = fetch_data, attrs) do
    GetRates.changeset(fetch_data, attrs)
  end
end