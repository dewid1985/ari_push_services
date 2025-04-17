defmodule Ari.Repo.Migrations.CreateSchemaInventory do
  use Ecto.Migration

  def up do
    execute "CREATE SCHEMA inventory"
  end

  def down do
    execute "DROP SCHEMA inventory CASCADE"
  end
end