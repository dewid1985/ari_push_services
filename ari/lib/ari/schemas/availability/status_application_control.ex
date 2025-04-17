defmodule Ari.Schemas.Availability.StatusApplicationControl do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "availability"

  # Define the schema for the `status_application_controls` table
  schema "status_application_controls" do
    # Define fields with their types
    field :start, :date           # The start date as a date in ISO8601 format
    field :end, :date             # The end date as a date in ISO8601 format
    field :mon, :boolean          # Boolean flag indicating availability on Monday
    field :sat, :boolean          # Boolean flag indicating availability on Saturday
    field :fri, :boolean          # Boolean flag indicating availability on Friday
    field :thur, :boolean         # Boolean flag indicating availability on Thursday
    field :weds, :boolean         # Boolean flag indicating availability on Wednesday
    field :tue, :boolean          # Boolean flag indicating availability on Tuesday
    field :sun, :boolean          # Boolean flag indicating availability on Sunday
    field :rate_plan_code, :string # Code representing the rate plan
    field :inv_type_code, :string  # Code representing the inventory type

    belongs_to :avail_status_message, Ari.Schemas.Availability.AvailStatusMessage

    has_many :destination_system_codes, Ari.Schemas.Availability.DestinationSystemCode

    timestamps()
  end


  # Creates a changeset for the `StatusApplicationControl` schema.
  #
  # This function prepares the data for insertion or update in the database by:
  # 1. Casting the provided attributes into the schema fields.
  # 2. Processing the embedded schema for destination system codes.
  # 3. Validating the date fields.
  def changeset(status_application_control, attrs) do
    status_application_control
    |> cast(attrs, [:start, :end, :mon, :sat, :fri, :thur, :weds, :tue, :sun, :rate_plan_code, :inv_type_code])
      # Cast the provided attributes into the schema fields
    |> cast_assoc(:destination_system_codes)
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

  # Checks the sequence of dates: the start date should not be after the end date,
  # and neither date should be in the past.
  #
  # This function handles different cases:
  # - When the start date is `nil`, an error is added indicating that the start date is invalid.
  # - When the end date is `nil`, an error is added indicating that the end date is invalid.
  # - If the start date is after the end date, an error is added indicating an invalid date combination.
  # - If either date is in the past, appropriate errors are added.
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
