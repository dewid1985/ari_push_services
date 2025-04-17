defmodule Ari.Schemas.Rate.BaseByGuestAmt do
  # Use Ecto.Schema to define the schema structure
  use Ecto.Schema
  # Import Ecto.Changeset to work with changesets (validation, casting, etc.)
  import Ecto.Changeset

  # Define the schema prefix, which is the "rate" schema in the database
  @schema_prefix "rate"

  # Define the schema "base_by_guest_amt" and its fields
  schema "base_by_guest_amt" do
    # Define an integer field for the maximum age
    field :max_age, :integer
    # Define an integer field for the minimum age
    field :min_age, :integer
    # Define a float field for the amount before tax
    field :amount_before_tax, :float
    # Define a float field for the amount after tax
    field :amount_after_tax, :float
    # Define an integer field for the number of guests
    field :number_of_guests, :integer
    # Define a string field for the age qualifying code (could represent age categories)
    field :age_qualifying_code, :string
    # Define an association that links to the Rate schema (belongs_to relationship)
    belongs_to :rate, Ari.Schemas.Rate.Rate

    # Automatically handled fields for when the record was inserted and last updated
    timestamps()
  end

  # Define a changeset function for validation and casting of attributes
  def changeset(base_by_guest_amt, attrs) do
    base_by_guest_amt
    # Cast the attributes into the changeset, limiting to specific fields
    |> cast(attrs, [:max_age, :min_age, :amount_before_tax, :amount_after_tax, :number_of_guests, :age_qualifying_code])
      # Ensure that certain fields are required (cannot be nil or blank)
    |> validate_required([:amount_before_tax, :amount_after_tax, :number_of_guests, :age_qualifying_code])
  end
end
