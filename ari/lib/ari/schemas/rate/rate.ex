defmodule Ari.Schemas.Rate.Rate do
  # Use Ecto.Schema to define the structure of the Rate schema
  use Ecto.Schema
  # Import Ecto.Changeset to work with changesets for validations and associations
  import Ecto.Changeset

  # Define the schema prefix as "rate", meaning that this schema will be part of the "rate" namespace
  @schema_prefix "rate"

  # Define the "rate" table schema
  schema "rate" do
    # Fields for the rate schema with their respective data types
    field :inv_type_code, :string  # Inventory type code, used to categorize different rate types
    field :currency_code, :string  # Currency code (e.g., USD, EUR) for the rate
    field :rate_time_unit, :string  # Time unit for the rate (e.g., daily, weekly)
    field :min_los, :integer  # Minimum Length of Stay (LOS) for this rate
    field :max_los, :integer  # Maximum Length of Stay (LOS) for this rate

    # Boolean fields representing availability of the rate on different days of the week
    field :sun, :boolean
    field :mon, :boolean
    field :tue, :boolean
    field :weds, :boolean
    field :thur, :boolean
    field :fri, :boolean
    field :sat, :boolean

    # Define a one-to-many relationship with the BaseByGuestAmt schema
    has_many :base_by_guest_amts, Ari.Schemas.Rate.BaseByGuestAmt
    # Define a many-to-one relationship with the RatePlan schema
    belongs_to :rate_plan, Ari.Schemas.Rate.RatePlan

    # Timestamps to track when the rate record was created or updated
    timestamps()
  end

  # Define a changeset function to validate and cast incoming data into the Rate schema
  def changeset(rate, attrs) do
    rate
    # Cast the incoming attributes for the fields that belong to the Rate schema
    |> cast(attrs, [:mon, :tue, :weds, :thur, :fri, :sat, :sun, :inv_type_code, :currency_code])
      # Cast the associated `base_by_guest_amts` field and ensure it is required
    |> cast_assoc(:base_by_guest_amts, required: true)
      # Validate that the fields `inv_type_code` and `currency_code` are present and not empty
    |> validate_required([:inv_type_code, :currency_code])
  end
end
