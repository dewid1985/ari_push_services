defmodule AriWeb.Form.HotelRatePlanNotifRqForm do
  use Ecto.Schema
  alias Ari.Schemas.Rate.UpdateRate

  def changeset(%UpdateRate{} = rate_massage, attrs) do
    UpdateRate.changeset(rate_massage, attrs)
  end
end