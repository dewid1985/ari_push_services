defmodule Ari.Repo.Migrations.CreateRateTables do
  use Ecto.Migration

  # This function defines the changes to be applied to the database schema
  def change do
    # Create the "ota_hotel_rate_plan_notif_rq" table with specified columns
    create table(:ota_hotel_rate_plan_notif_rq, prefix: "rate") do
      add :time_stamp, :utc_datetime_usec # Timestamp when the notification was sent
      add :version, :string, size: 16       # Version of the notification protocol
      add :message_content_code, :string, size: 8  # Code specifying the content of the message
      add :outside_id, :string, size: 256
      add :message_id, :integer
      add :customer_code, :string, size: 256
      add :active, :boolean, default: true, null: true
      add :inserted_at, :utc_datetime       # Auto-populated field for when the row was inserted
      add :updated_at, :utc_datetime        # Auto-populated field for when the row was last updated
    end

    # Add index to message_id and customer_code
    create index(:ota_hotel_rate_plan_notif_rq, [:message_id], prefix: "rate")
    create index(:ota_hotel_rate_plan_notif_rq, [:customer_code], prefix: "rate")
    create index(:ota_hotel_rate_plan_notif_rq, [:outside_id], prefix: "rate")

    # Create the "rate_plans" table, referencing "ota_hotel_rate_plan_notif_rq"
    create table(:rate_plans, prefix: "rate") do
      add :ota_hotel_rate_plan_notif_rq_id, references(:ota_hotel_rate_plan_notif_rq, on_delete: :nothing, prefix: "rate")
      add :hotel_code, :string, size: 16    # Code identifying the hotel
      add :inserted_at, :utc_datetime       # When the row was inserted
      add :updated_at, :utc_datetime        # When the row was last updated
    end

    # Add index to ota_hotel_rate_plan_notif_rq_id and hotel_code
    create index(:rate_plans, [:ota_hotel_rate_plan_notif_rq_id], prefix: "rate")
    create index(:rate_plans, [:hotel_code], prefix: "rate")

    # Create the "rate_plan" table, referencing "rate_plans"
    create table(:rate_plan, prefix: "rate") do
      add :rate_plans_id, references(:rate_plans, on_delete: :nothing, prefix: "rate")  # Foreign key to "rate_plans"
      add :rate_plan_code, :string, size: 32  # Unique code for the rate plan
      add :rate_plan_notif_type, :string      # Type of the notification for the rate plan
      add :start, :date                       # Start date of the rate plan
      add :end, :date                         # End date of the rate plan
      add :inserted_at, :utc_datetime         # Insertion timestamp
      add :updated_at, :utc_datetime          # Update timestamp
    end

    # Add index to rate_plans_id
    create index(:rate_plan, [:rate_plans_id], prefix: "rate")

    # Create the "unique_id" table, referencing "rate_plan"
    create table(:unique_id, prefix: "rate") do
      add :rate_plan_id, references(:rate_plan, on_delete: :nothing, prefix: "rate")  # Foreign key to "rate_plan"
      add :type, :string, size: 256      # Type of unique ID (e.g., OTA code)
      add :code, :string, size: 16       # Unique code
      add :inserted_at, :utc_datetime    # Insertion timestamp
      add :updated_at, :utc_datetime     # Update timestamp
    end

    # Add index to rate_plan_id in unique_id table
    create index(:unique_id, [:rate_plan_id], prefix: "rate")

    # Create the "rate" table, referencing "rate_plan"
    create table(:rate, prefix: "rate") do
      add :rate_plan_id, references(:rate_plan, on_delete: :nothing, prefix: "rate")  # Foreign key to "rates"
      add :inv_type_code, :string, size: 32  # Inventory type code (e.g., room type)
      add :currency_code, :string, size: 3   # Currency code for the rate (e.g., USD)
      add :rate_time_unit, :string, size: 32  # Unit of time for the rate (e.g., nightly)
      add :min_los, :integer                # Minimum length of stay
      add :max_los, :integer                # Maximum length of stay
      add :sun, :boolean                    # Availability on Sunday
      add :mon, :boolean                    # Availability on Monday
      add :tue, :boolean                    # Availability on Tuesday
      add :weds, :boolean                   # Availability on Wednesday
      add :thur, :boolean                   # Availability on Thursday
      add :fri, :boolean                    # Availability on Friday
      add :sat, :boolean                    # Availability on Saturday
      add :inserted_at, :utc_datetime       # Insertion timestamp
      add :updated_at, :utc_datetime        # Update timestamp
    end

    # Add index to rate_plan_id in rate table
    create index(:rate, [:rate_plan_id], prefix: "rate")

    # Create the "base_by_guest_amt" table, referencing "rate"
    create table(:base_by_guest_amt, prefix: "rate") do
      add :rate_id, references(:rate, on_delete: :nothing, prefix: "rate")  # Foreign key to "base_by_guest_amts"
      add :max_age, :integer                 # Maximum age for guest pricing
      add :min_age, :integer                 # Minimum age for guest pricing
      add :amount_before_tax, :float         # Amount before tax
      add :amount_after_tax, :float          # Amount after tax
      add :number_of_guests, :integer        # Number of guests
      add :age_qualifying_code, :string, size: 32  # Age qualifier (e.g., adult or child)
      add :inserted_at, :utc_datetime        # Insertion timestamp
      add :updated_at, :utc_datetime         # Update timestamp
    end

    # Add index to rate_id in base_by_guest_amt table
    create index(:base_by_guest_amt, [:rate_id], prefix: "rate")

    # Create the "destination_system_code" table, referencing "destination_system_code"
    create table(:destination_system_code, prefix: "rate") do
      add :rate_plan_id, references(:rate_plan, on_delete: :nothing, prefix: "rate")  # Foreign key to "destination_systems_code"
      add :text, :string, size: 32         # Descriptive text for the system code
      add :inserted_at, :utc_datetime      # Insertion timestamp
      add :updated_at, :utc_datetime       # Update timestamp
    end

    # Add index to rate_plan_id in destination_system_code table
    create index(:destination_system_code, [:rate_plan_id], prefix: "rate")
  end
end
