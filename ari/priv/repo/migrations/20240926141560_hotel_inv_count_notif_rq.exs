defmodule MyApp.Repo.Migrations.HotelInvCountNotifRQ do
  use Ecto.Migration

  def change do
    # Main table for OTA_HotelInvCountNotifRQ
    create table(:ota_hotel_inv_count_notif_rq, prefix: "inventory") do
      add :time_stamp, :utc_datetime_usec, null: false, comment: "Timestamp when the notification was sent"
      add :version, :string, size: 16, null: false, comment: "Version of the notification protocol"
      add :message_content_code, :string, size: 8, comment: "Message content code"
      add :outside_id, :string, size: 256, null: true
      add :message_id, :integer
      add :customer_code, :string, size: 256
      add :active, :boolean, default: true, null: true
      add :inserted_at, :utc_datetime       # Auto-populated field for when the row was inserted
      add :updated_at, :utc_datetime
    end

    create index(:ota_hotel_inv_count_notif_rq, [:message_id], prefix: "inventory")
    create index(:ota_hotel_inv_count_notif_rq, [:outside_id], prefix: "inventory")
    create index(:ota_hotel_inv_count_notif_rq, [:customer_code], prefix: "inventory")

    # Table for Inventories (embedded in the OTA notification)
    create table(:inventories, prefix: "inventory") do
      add :hotel_code, :string, size: 256, null: false, comment: "Hotel code from the Inventories element"
      add :ota_hotel_inv_count_notif_rq_id, references(:ota_hotel_inv_count_notif_rq, on_delete: :delete_all, prefix: "inventory"), null: false

      # If there is a UniqueID element for Inventories, you could add:
      # add :unique_id_type, :string, comment: "Type attribute from UniqueID element"

      add :inserted_at, :utc_datetime       # Auto-populated field for when the row was inserted
      add :updated_at, :utc_datetime
    end

    create index(:inventories, [:ota_hotel_inv_count_notif_rq_id], prefix: "inventory")
    create index(:inventories, [:hotel_code], prefix: "inventory")

    # Table for UniqueIDs associated with Inventories.
    create table(:unique_id, prefix: "inventory") do
      add :inventories_id, references(:inventories, on_delete: :delete_all), null: false
      add :type, :string, size: 256, comment: "Type attribute from the UniqueID element"
      add :code, :string, size: 16, comment: "Unique identifier value from the UniqueID element"
      add :inserted_at, :utc_datetime       # Auto-populated field for when the row was inserted
      add :updated_at, :utc_datetime
    end

    create index(:unique_id, [:inventories_id], prefix: "inventory")

    # Table for individual Inventory items (each <Inventory> element)
    create table(:inventory, prefix: "inventory") do
      add :inventories_id, references(:inventories, on_delete: :delete_all, prefix: "inventory"), null: false
      add :inserted_at, :utc_datetime       # Auto-populated field for when the row was inserted
      add :updated_at, :utc_datetime
    end

    create index(:inventory, [:inventories_id], prefix: "inventory")

    # Table for StatusApplicationControl within each Inventory item
    create table(:status_application_controls, prefix: "inventory") do
      add :start, :date, null: false, comment: "Start date of the control period"
      add :end, :date, null: false, comment: "End date of the control period"
      add :inv_type_code, :string, size: 64, null: false, comment: "Inventory type code"
      add :inventory_id, references(:inventory, on_delete: :delete_all,  prefix: "inventory"), null: false

      add :inserted_at, :utc_datetime       # Auto-populated field for when the row was inserted
      add :updated_at, :utc_datetime
    end

    create index(:status_application_controls, [:inventory_id], prefix: "inventory")

    # Table for DestinationSystemCodes within StatusApplicationControl
    create table(:destination_system_code, prefix: "inventory") do
      add :status_application_control_id, references(:status_application_controls, on_delete: :delete_all,  prefix: "inventory"), null: false

      add :text, :string, size: 64, null: false, comment: "Destination system code"
      add :inserted_at, :utc_datetime       # Auto-populated field for when the row was inserted
      add :updated_at, :utc_datetime
    end

    create index(:destination_system_code, [:status_application_control_id], prefix: "inventory")

    # Table for InvCounts (each <InvCount> element is stored here, associated with an Inventory item)
    create table(:inv_counts, prefix: "inventory") do
      add :inventory_id, references(:inventory, on_delete: :delete_all), null: false
      add :inserted_at, :utc_datetime       # Auto-populated field for when the row was inserted
      add :updated_at, :utc_datetime
    end

    create index(:inv_counts, [:inventory_id], prefix: "inventory", prefix: "inventory")

    create table(:inv_count, prefix: "inventory") do
      add :count_type, :string, size: 64, null: false, comment: "Type of count (e.g., '2' or '3')"
      add :count, :integer, null: false, comment: "Inventory count value"
      add :inv_counts_id, references(:inv_counts, on_delete: :delete_all, prefix: "inventory"), null: false

      add :inserted_at, :utc_datetime       # Auto-populated field for when the row was inserted
      add :updated_at, :utc_datetime
    end
  end
end