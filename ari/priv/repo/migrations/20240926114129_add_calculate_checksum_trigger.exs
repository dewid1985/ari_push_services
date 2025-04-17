defmodule Ari.Repo.Migrations.AddCalculateChecksumTrigger do
  use Ecto.Migration

  # The `up` function defines the operations that will be executed when this migration is run.
  def up do
    # Execute SQL to create a custom PostgreSQL function to calculate the checksum based on XML content.
    execute("""
    CREATE FUNCTION public.calculate_checksum() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
        -- Variable to store the request body extracted from the XML content
        request_body    TEXT;
        lock_key BIGINT;

        -- Array of namespaces to be used when extracting data from the XML using xpath
        namespace_array TEXT[][] := ARRAY [
            ARRAY ['soap', 'http://www.w3.org/2003/05/soap-envelope'],
            ARRAY ['ota', 'http://www.opentravel.org/OTA/2003/05']
        ];
    BEGIN
        -- Log a notice for debugging purposes, indicating the trigger has started for the given request_id
        RAISE NOTICE 'calculate_checksum started trigger for request_id: %', NEW.id;

        -- Extract the request body for Availability Notification using xpath with namespaces
        request_body := xpath('/soap:Envelope/soap:Body/ota:OTA_HotelAvailNotifRQ/*',
                              NEW.request::xml, -- Convert the 'request' field to XML for processing
                              namespace_array
            )::TEXT; -- Cast the result as TEXT

        -- If the extracted request body is not empty, proceed with checksum calculation
        IF request_body <> '{}' THEN
            -- Generate a SHA-1 checksum from the request body
            NEW.checksum := encode(digest(request_body, 'sha1'), 'hex');

             -- Compute an advisory lock key based on the checksum.
            lock_key := ('x' || substr(NEW.checksum, 1, 16))::bit(64)::bigint;
            -- Acquire the advisory lock for the current transaction.
            PERFORM pg_advisory_xact_lock(lock_key);

            -- Mark other records with the same checksum as duplicates (set 'double' to true)
            UPDATE messages
            SET double = true
            WHERE checksum = NEW.checksum AND active = true AND NOT id = NEW.id;

            -- Return the modified NEW record with the calculated checksum
            RETURN NEW;
        END IF;

        -- Extract the request body for Rate Plan Notification
        request_body := xpath('/soap:Envelope/soap:Body/ota:OTA_HotelRatePlanNotifRQ/*',
                              NEW.request::xml,
                              namespace_array
            )::TEXT;

        -- If the extracted request body is not empty, calculate the checksum
        IF request_body <> '{}' THEN
            NEW.checksum := encode(digest(request_body, 'sha1'), 'hex');

            -- Compute an advisory lock key based on the checksum.
            lock_key := ('x' || substr(NEW.checksum, 1, 16))::bit(64)::bigint;
            -- Acquire the advisory lock for the current transaction.
            PERFORM pg_advisory_xact_lock(lock_key);

            -- Update the 'double' field for duplicate records with the same checksum
            UPDATE messages
            SET double = true
            WHERE checksum = NEW.checksum AND active = true AND NOT id = NEW.id;

            -- Return the updated NEW record
            RETURN NEW;
        END IF;

        -- Extract the request body for Inventory Notification
        request_body := xpath('/soap:Envelope/soap:Body/ota:OTA_HotelInvCountNotifRQ/*',
                              NEW.request::xml,
                              namespace_array
            )::TEXT;

        -- If the extracted request body is not empty, calculate the checksum
        IF request_body <> '{}' THEN
            NEW.checksum := encode(digest(request_body, 'sha1'), 'hex');

            -- Compute an advisory lock key based on the checksum.
            lock_key := ('x' || substr(NEW.checksum, 1, 16))::bit(64)::bigint;
            -- Acquire the advisory lock for the current transaction.
            PERFORM pg_advisory_xact_lock(lock_key);

            -- Mark other records with the same checksum as duplicates
            UPDATE messages
            SET double = true
            WHERE checksum = NEW.checksum AND active = true AND NOT id = NEW.id;

            -- Return the updated NEW record
            RETURN NEW;
        END IF;

        -- Return the new record if no specific conditions were met (no checksum calculation)
        RETURN NEW;
    END;
    $$;
    """)

    # Create the trigger that will invoke the above function before each INSERT on the 'messages' table.
    execute("""
    CREATE TRIGGER calculate_checksum_trigger
    BEFORE INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_checksum();
    """)
  end

  # The `down` function defines how to rollback this migration (i.e., undo the `up` migration).
  def down do
    # Remove the trigger if it exists
    execute("DROP TRIGGER IF EXISTS calculate_checksum_trigger ON public.messages")

    # Remove the custom function if it exists
    execute("DROP FUNCTION IF EXISTS public.calculate_checksum()")
  end

end
