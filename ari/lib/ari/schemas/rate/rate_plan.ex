defmodule Ari.Schemas.Rate.RatePlan do
  use Ecto.Schema  # Import Ecto.Schema to define the database schema.
  import Ecto.Changeset  # Import Ecto.Changeset for handling changes and validations.

  @schema_prefix "rate"  # Set a schema prefix for this table to differentiate it from others.

  # Define the schema for the `rate_plan` table in the database.
  schema "rate_plan" do
    field :start, :date  # The start date of the rate plan.
    field :end, :date    # The end date of the rate plan.
    field :rate_plan_code, :string  # A code representing the rate plan.
    field :rate_plan_notif_type, :string  # Type of notification for the rate plan.

    # Associations:
    belongs_to :rate_plans, Ari.Schemas.Rate.RatePlans  # Foreign key relation to the RatePlans schema.
    has_one :unique_id, Ari.Schemas.Rate.UniqueId  # One-to-one relation with UniqueId.
    has_many :destination_systems_code, Ari.Schemas.Rate.DestinationSystemCode  # One-to-many relation with DestinationSystemCode.
    has_many :rates, Ari.Schemas.Rate.Rate  # One-to-many relation with Rate.

    timestamps()  # Automatically adds `inserted_at` and `updated_at` fields.
  end

  # Creates a changeset for the `RatePlan` schema, validating fields and embedded structures.
  #
  # This function:
  # 1. Casts the provided attributes into the schema fields.
  # 2. Validates the presence of required fields.
  # 3. Processes the embedded schemas for unique ID, destination system codes, and rates.
  # 4. Validates the date fields.
  def changeset(rate_plan, attrs) do
    rate_plan
    |> cast(attrs, [:start, :end, :rate_plan_code, :rate_plan_notif_type])  # Cast specified attributes.
    |> validate_required([:start, :end])  # Ensure that `start` and `end` are present.
    |> cast_assoc(:unique_id)  # Cast the associated unique_id.
    |> cast_assoc(:destination_systems_code)  # Cast associated destination system codes.
    |> cast_assoc(:rates)  # Cast associated rates.
    |> validate_dates()  # Validate the date fields after casting.
  end

  # Validates the date fields for correctness and logical sequence.
  #
  # This function checks:
  # 1. That the start date and end date are present.
  # 2. That the start date is not after the end date.
  # 3. That neither date is in the past.
  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start)  # Retrieve the start date from the changeset.
    end_date = get_field(changeset, :end)  # Retrieve the end date from the changeset.

    # Call the date comparison validation function.
    changeset
    |> validate_date_comparison(start_date, end_date)
  end

  # Checks the sequence and validity of the dates:
  # - Ensures the start date is not after the end date.
  # - Ensures neither date is in the past.
  #
  # Handles different scenarios:
  # - If the start date is `nil`, adds an error indicating that the start date is missing.
  # - If the end date is `nil`, adds an error indicating that the end date is missing.
  # - If the start date is in the past, adds an error for an invalid start date.
  # - If the end date is in the past, adds an error for an invalid end date.
  # - If the start date is after the end date, adds an error for an invalid date combination.
  defp validate_date_comparison(changeset, nil, _end_date) do
    # Error when start date is missing
    add_error(changeset, :start, "136|Start Date is Invalid")
  end

  defp validate_date_comparison(changeset, _start_date, nil) do
    # Error when end date is missing
    add_error(changeset, :end, "135|End Date is Invalid")
  end

  defp validate_date_comparison(changeset, start_date, end_date) do
    today = Date.utc_today()  # Get the current date.

    # Compare dates and handle validation scenarios
    case {Date.compare(start_date, today), Date.compare(end_date, today), Date.compare(start_date, end_date)} do
      {:lt, _end_cmp, _} ->
        # Error when start date is in the past
        add_error(changeset, :start, "136|Start Date is Invalid")

      {_, :lt, _} ->
        # Error when end date is in the past
        add_error(changeset, :end, "135|End Date is Invalid")

      {_, _, :gt} ->
        # Error when start date is after the end date
        add_error(changeset, :start, "404|Invalid Start/End Date Combination")

      _ ->
        changeset  # Return the unchanged changeset if all validations pass.
    end
  end
end
