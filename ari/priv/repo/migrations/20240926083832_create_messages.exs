defmodule Ari.Repo.Migrations.CreateMessagesTable do
  use Ecto.Migration

  def change do
    create table(:messages, prefix: "public") do
      add :entity_id, :bigint
      add :hotel_code, :string
      add :double, :boolean, defaulf: false, null: false
      add :error, :boolean, default: false, null: false
      add :user_name, :string
      add :rate, :boolean, default: false, null: false
      add :availability, :boolean, default: false, null: false
      add :inventory, :boolean, default: false, null: false
      add :time_stamp, :naive_datetime
      add :internal_id, :string
      add :outside_id, :string
      add :customer_code, :string
      add :active, :boolean, default: true, null: true
      add :checksum, :string
      add :request, :text
      add :response, :text
      add :deleted_at, :utc_datetime
      add :inserted_at, :utc_datetime
      add :updated_at, :utc_datetime
    end

    create index(:messages, [:hotel_code], prefix: "public")
    create index(:messages, [:internal_id], prefix: "public")
    create index(:messages, [:outside_id], prefix: "public")
    create index(:messages, [:deleted_at], prefix: "public")
    create index(:messages, [:inserted_at], prefix: "public")
    create index(:messages, [:updated_at], prefix: "public")
    create index(:messages, [:checksum], prefix: "public")
    create index(:messages, [:user_name], prefix: "public")
    create index(:messages, [:entity_id], prefix: "public")
    create index(:messages, [:customer_code], prefix: "public")
  end
end
