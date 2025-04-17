defmodule Ari.Schemas.Inventory.StatusApplicationControl do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "inventory"

  # Define the schema for the `status_application_controls` table
  schema "status_application_controls" do
    field :start, :date
    field :end, :date
    belongs_to :inventory, Ari.Schemas.Inventory.Inventory
    has_many :distination_system_codes, Ari.Schemas.Inventory.DestinationSystemCode
    field :inv_type_code, :string
  end


  # Creates a changeset for the `StatusApplicationControl` schema.
  #
  # This function prepares the data for insertion or update in the database by:
  # 1. Casting the provided attributes into the schema fields.
  # 2. Validating that the required fields are present.
  # 3. Processing the embedded schema for destination system codes.
  # 4. Validating the date fields.
  def changeset(status_application_control, attrs) do
    IO.inspect(attrs)
    status_application_control
    |> cast(attrs, [:start, :end, :inv_type_code])
      # Cast the provided attributes into the schema fields
    |> validate_required([:start, :end, :inv_type_code])
      # Ensure that the required fields are present
    |> cast_assoc(:distination_system_codes)
      # Process the embedded schema for destination system codes
    |> validate_dates()
    # Validate the date fields
  end


  # Validates the date fields for correctness and logical sequence.
  #
  # This function checks:
  # 1. That the start date and end date are present.
  # 2. That the start date is not after the end date.
  # 3. That neither date is in the past.
  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start)
    end_date = get_field(changeset, :end)

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
  # - If the start date is after the end date, adds an error for invalid date combination.
  defp validate_date_comparison(changeset, nil, _end_date) do
    # Error when start date is missing
    add_error(changeset, :start, "136|Start Date is Invalid")
  end

  defp validate_date_comparison(changeset, _start_date, nil) do
    # Error when end date is missing
    add_error(changeset, :end, "135|End Date is Invalid")
  end

  defp validate_date_comparison(changeset, start_date, end_date) do
    today = Date.utc_today()

    case {Date.compare(start_date, today), Date.compare(end_date, today), Date.compare(start_date, end_date)} do
      {:lt, _, _} ->
        # Error when start date is in the past
        add_error(changeset, :start, "136|Start Date is Invalid")

      {_, :lt, _} ->
        # Error when end date is in the past
        add_error(changeset, :end, "135|End Date is Invalid")

      {_, _, :gt} ->
        # Error when start date is after the end date
        add_error(changeset, :start, "404|Invalid Start/End Date Combination")

      _ ->
        changeset
    end
  end
end
