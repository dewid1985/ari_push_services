defmodule Ari.Schemas.Rate.UpdateRateBody do
  # Use Ecto.Schema to define the structure for the embedded schema
  use Ecto.Schema
  # Import Ecto.Changeset to work with changesets, including casting and validation
  import Ecto.Changeset

  # Define suschimoto an embedded schema, meaning that it is not a table in the database but nested data
  embedded_schema do
    # Define an embedded association for ota_hotel_rate_plan_notif_rq
    # It uses the OtaHotelRatePlanNotifRQ schema, which is embedded within this schema
    embeds_one :ota_hotel_rate_plan_notif_rq, Ari.Schemas.Rate.OtaHotelRatePlanNotifRQ
  end

  # Define a changeset function to handle validations and casting for the schema
  def changeset(body, attrs) do
    body
    # Cast attributes, here there are no direct fields to cast in the current schema
    |> cast(attrs, [])
      # Cast and validate the embedded schema (:ota_hotel_rate_plan_notif_rq)
      # The embedded field is required for this schema to be valid
    |> cast_embed(:ota_hotel_rate_plan_notif_rq, required: true)
  end
end
