defmodule Ari.Repo.Migrations.CreateHotelAvailNotifRq do
  use Ecto.Migration

  def change do
    # Основная таблица для OTA_HotelAvailNotifRQ
    create table(:ota_hotel_avail_notif_rq, prefix: "availability") do
      add :time_stamp, :utc_datetime_usec, null: false, comment: "Timestamp when the notification was sent"
      add :version, :string, size: 16, null: false, comment: "Version of the notification protocol"
      add :message_content_code, :string, size: 8, comment: "Message content code"
      add :outside_id, :string, size: 256
      add :message_id, :integer
      add :customer_code, :string, size: 256
      add :active, :boolean, null: false, default: true
      add :inserted_at, :utc_datetime       # Auto-populated field for when the row was inserted
      add :updated_at, :utc_datetime
    end

    create index(:ota_hotel_avail_notif_rq, [:message_id], prefix: "availability")
    create index(:ota_hotel_avail_notif_rq, [:outside_id], prefix: "availability")
    create index(:ota_hotel_avail_notif_rq, [:customer_code], prefix: "availability")

    # Таблица для контейнерного элемента AvailStatusMessages (хранит HotelCode)
    create table(:avail_status_messages, prefix: "availability") do
      add :ota_hotel_avail_notif_rq_id, references(:ota_hotel_avail_notif_rq, on_delete: :delete_all, prefix: "availability"), null: false
      add :hotel_code, :string, size: 256, null: false, comment: "Hotel code from AvailStatusMessages/@HotelCode"
      timestamps()
    end

    create index(:avail_status_messages, [:ota_hotel_avail_notif_rq_id], prefix: "availability")
    create index(:avail_status_messages, [:hotel_code], prefix: "availability")

    # Таблица для каждого элемента AvailStatusMessage
    create table(:avail_status_message, prefix: "availability") do
      add :avail_status_messages_id, references(:avail_status_messages, on_delete: :delete_all, prefix: "availability"), null: false
      timestamps()
    end

    create index(:avail_status_message, [:avail_status_messages_id], prefix: "availability")

    # Отдельная таблица для StatusApplicationControl (вложенный в AvailStatusMessage)
    create table(:status_application_controls, prefix: "availability") do
      add :avail_status_message_id, references(:avail_status_message, on_delete: :delete_all, prefix: "availability"), null: false
      add :start, :date, null: false, comment: "Start date from StatusApplicationControl/@Start"
      add :end, :date, null: false, comment: "End date from StatusApplicationControl/@End"
      add :rate_plan_code, :string, size: 64, comment: "Rate plan code from StatusApplicationControl/@RatePlanCode"
      add :inv_type_code, :string, size: 64, comment: "Inventory type code from StatusApplicationControl/@InvTypeCode"
      add :mon, :boolean, comment: "Monday restriction from @Mon"
      add :tue, :boolean, comment: "Tuesday restriction from @Tue"
      add :weds, :boolean, comment: "Wednesday restriction from @Weds"
      add :thur, :boolean, comment: "Thursday restriction from @Thur"
      add :fri, :boolean, comment: "Friday restriction from @Fri"
      add :sat, :boolean, comment: "Saturday restriction from @Sat"
      add :sun, :boolean, comment: "Sunday restriction from @Sun"
      timestamps()
    end

    create index(:status_application_controls, [:avail_status_message_id], prefix: "availability")

    # Отдельная таблица для DestinationSystemCodes (вложенный в StatusApplicationControl)
    create table(:destination_system_code, prefix: "availability") do
      add :status_application_control_id, references(:status_application_controls, on_delete: :delete_all, prefix: "availability"), null: false
      add :text, :string, size: 64, null: false, comment: "Destination system code from DestinationSystemCode element"
      timestamps()
    end

    create index(:destination_system_code, [:status_application_control_id], prefix: "availability")

    # Отдельная таблица для UniqueID (вложенный напрямую в AvailStatusMessage)
    create table(:unique_id, prefix: "availability") do
      add :avail_status_message_id, references(:avail_status_message, on_delete: :delete_all, prefix: "availability"), null: false
      add :code, :string, size: 64, null: false, comment: "Unique identifier value from UniqueID/@ID"
      add :type, :string, size: 256, comment: "Type attribute from UniqueID element"
      timestamps()
    end

    create index(:unique_id, [:avail_status_message_id], prefix: "availability")

    # Отдельная таблица для RestrictionStatus (вложенный в AvailStatusMessage)
    create table(:restriction_status, prefix: "availability") do
      add :avail_status_message_id, references(:avail_status_message, on_delete: :delete_all, prefix: "availability"), null: false
      add :restriction, :string, size: 64, comment: "Restriction from RestrictionStatus/@Restriction"
      add :status, :string, size: 64, comment: "Status from RestrictionStatus/@Status"
      add :max_advanced_booking_offset, :string, size: 64, comment: "Max advanced booking offset from RestrictionStatus/@MaxAdvancedBookingOffset"
      add :min_advanced_booking_offset, :string, size: 64, comment: "Min advanced booking offset from RestrictionStatus/@MinAdvancedBookingOffset"
      timestamps()
    end

    create index(:restriction_status, [:avail_status_message_id], prefix: "availability")

    # Отдельная таблица для контейнера LengthsOfStay (вложенный в AvailStatusMessage)
    create table(:lengths_of_stay, prefix: "availability") do
      add :avail_status_message_id, references(:avail_status_message, on_delete: :delete_all, prefix: "availability"), null: false
      add :fixed_pattern_length, :string, size: 64, comment: "Optional fixed pattern length from LengthsOfStay/@FixedPatternLength"
      timestamps()
    end

    create index(:lengths_of_stay, [:avail_status_message_id], prefix: "availability")

    # Отдельная таблица для каждого элемента LengthOfStay (вложенный в LengthsOfStay)
    create table(:length_of_stay, prefix: "availability") do
      add :lengths_of_stay_id, references(:lengths_of_stay, on_delete: :delete_all, prefix: "availability"), null: false
      add :min_max_message_type, :string, size: 64, comment: "MinMaxMessageType from LengthOfStay/@MinMaxMessageType"
      add :time_unit, :string, size: 32, comment: "Time unit from LengthOfStay/@TimeUnit"
      add :time, :string, size: 32, comment: "Time from LengthOfStay/@Time"
      timestamps()
    end

    create index(:length_of_stay, [:lengths_of_stay_id], prefix: "availability")
  end
end
