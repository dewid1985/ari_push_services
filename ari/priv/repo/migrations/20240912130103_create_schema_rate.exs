defmodule Ari.Repo.Migrations.CreateSchemaRate do
  use Ecto.Migration

  def up do
    execute "CREATE SCHEMA rate"
  end

  def down do
    execute "DROP SCHEMA rate CASCADE"
  end
end