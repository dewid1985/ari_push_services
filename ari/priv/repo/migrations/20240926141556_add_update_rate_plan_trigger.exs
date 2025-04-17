defmodule YourApp.Repo.Migrations.AddUpdateOtaRatePlanTrigger do
  use Ecto.Migration

  def up do
    # Create a PL/pgSQL function that will be executed whenever the 'double' field is updated
    execute("""
    CREATE OR REPLACE FUNCTION public.update_ota_rate_plan_active()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        -- Check if 'rate' is true and 'double' has changed from false to true
        IF NEW.rate = true AND OLD.double = false AND NEW.double = true THEN
            -- Update the 'active' field in the 'ota_hotel_rate_plan_notif_rq' table to false
            -- where the 'id' in that table matches the 'entity_id' of the updated message record
            UPDATE rate.ota_hotel_rate_plan_notif_rq
            SET active = false
            WHERE id = NEW.entity_id;
        END IF;

        -- Return the updated row
        RETURN NEW;
    END;
    $$;
    """)

    # Create a trigger that fires after the 'double' field in the 'messages' table is updated
    # This trigger is activated when 'double' is updated from false to true, and 'rate' is true
    execute("""
    CREATE TRIGGER update_rate_plan_trigger
    AFTER UPDATE OF double
    ON messages
    FOR EACH ROW
    -- The condition ensures that the trigger only fires when 'double' changes from false to true,
    -- and 'rate' is true, avoiding unnecessary executions.
    WHEN (OLD.double = false AND NEW.double = true AND NEW.rate = true)
    -- Execute the function defined above to update the related 'ota_hotel_rate_plan_notif_rq' record
    EXECUTE FUNCTION public.update_ota_rate_plan_active();
    """)
  end

  def down do
    # In case of rollback, drop the trigger to avoid keeping it in the database
    execute("DROP TRIGGER IF EXISTS update_rate_plan_trigger ON messages")

    # Drop the function to clean up the schema if we rollback
    execute("DROP FUNCTION IF EXISTS public.update_ota_rate_plan_active()")
  end
end
