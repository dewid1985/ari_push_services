defmodule Ari.Schemas.Rate.RatePlans do
  use Ecto.Schema  # Import Ecto.Schema to define the database schema.
  import Ecto.Changeset  # Import Ecto.Changeset for handling changes and validations.

  @schema_prefix "rate"  # Set a schema prefix for this table, helping to namespace it in the database.

  # Define the schema for the `rate_plans` table in the database.
  schema "rate_plans" do
    field :hotel_code, :string  # A string field representing the hotel code associated with the rate plans.

    # Associations:
    belongs_to :ota_hotel_rate_plan_notif_rq, Ari.Schemas.Rate.OtaHotelRatePlanNotifRQ  # Foreign key relation to the OtaHotelRatePlanNotifRQ schema.
    has_many :rate_plan, Ari.Schemas.Rate.RatePlan  # One-to-many relation with RatePlan.

    timestamps()  # Automatically adds `inserted_at` and `updated_at` fields to track changes.
  end

  # Creates a changeset for the `RatePlans` schema, validating fields and associated structures.
  def changeset(rate_plans, attrs) do
    rate_plans
    |> cast(attrs, [:hotel_code])  # Cast the provided attributes into the schema fields.
    |> validate_required([:hotel_code])  # Ensure that `hotel_code` is present.
    |> cast_assoc(:rate_plan, required: true)  # Cast associated rate_plan, ensuring it is required.
  end
end
