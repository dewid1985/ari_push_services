defmodule Ari.Repo.Migrations.CreateSchemaAvailability do
  use Ecto.Migration

  def up do
    execute "CREATE SCHEMA availability"
  end

  def down do
    execute "DROP SCHEMA availability CASCADE"
  end
end