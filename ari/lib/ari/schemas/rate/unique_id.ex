defmodule Ari.Schemas.Rate.UniqueId do
  use Ecto.Schema  # Import Ecto.Schema to define the schema for UniqueId.
  import Ecto.Changeset  # Import Ecto.Changeset to handle changes and validations for the schema.

  # Define the schema for the `unique_id` table.
  schema "unique_id" do
    # Define a string field for the type of unique ID (e.g., "internal", "external").
    field :type, :string
    # Define a string field for the unique ID code itself.
    field :code, :string
    # Establish a belongs_to association with the RatePlan schema, linking the unique ID to a specific rate plan.
    belongs_to :rate_plan, Ari.Schemas.Rate.RatePlan
    timestamps()  # Automatically adds `inserted_at` and `updated_at` timestamps.
  end

  # Creates a changeset for the `UniqueId` schema, validating the provided attributes.
  #
  # This function:
  # 1. Accepts the current `unique_id` struct and a map of attributes.
  # 2. Casts the attributes into the schema fields.
  # 3. Validates the presence of required fields.
  def changeset(unique_id, attrs) do
    unique_id
    |> cast(attrs, [:type, :code])  # Cast only the `type` and `code` fields from the incoming attributes.
    |> validate_required([:type, :code])  # Ensure both fields are present in the changeset.
  end
end