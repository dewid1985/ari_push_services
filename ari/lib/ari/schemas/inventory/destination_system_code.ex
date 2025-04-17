defmodule Ari.Schemas.Inventory.DestinationSystemCode do
  # Use Ecto.Schema to define the structure of the schema
  use Ecto.Schema
  # Import Ecto.Changeset to work with changesets, including casting and validation
  import Ecto.Changeset

  # Specify the schema prefix for the table, "rate" in this case
  @schema_prefix "inventory"

  # Define the schema for the "destination_system_code" table
  schema "destination_system_code" do
    # Define the fields for the schema. `text` is a string field
    field :text, :string
    # Define a belongs_to association with the `rate_plan` schema
    belongs_to :status_application_control, Ari.Schemas.Inventory.StatusApplicationControl
    # Automatically generate inserted_at and updated_at timestamps
    timestamps()
  end

  # Define a changeset function to handle validations and casting
  def changeset(destination_system_code, attrs) do
    destination_system_code
    # Cast the `attrs` (attributes) to the `destination_system_code` schema, allowing changes to the `text` field
    |> cast(attrs, [:text])
      # Ensure that the `text` field is present (required)
    |> validate_required([:text])
  end
end
