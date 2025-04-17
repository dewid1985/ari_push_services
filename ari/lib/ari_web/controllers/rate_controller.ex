defmodule AriWeb.RateController do
  use AriWeb, :controller
  require Logger
  alias Ari.Repo

  alias Ari.{Accounts}
  alias Ari.Schemas.Rate.{UpdateRate, GetRates}
  alias Ari.Contexts.Rate.{OtaHotelRatePlanNotifRQ}
  alias Ari.Schemas.Public.{Message}
  alias Ari.Schemas.Shared.{FetchData}

  alias Ecto.{Multi, Changeset}

  alias AriWeb.{OtaResponse}
  alias AriWeb.Form.{HotelRatePlanNotifRqForm, DataFetchForm}
  alias AriWeb.Form.{DataFetchForm}

  @resource "soap"

  @doc """
  Handles a GET rates request.

  Process overview:
    1. Parse the cleaned XML request body from the connection’s private data.
    2. Build a changeset for the GetRates schema using the parsed request data.
    3. Extract nested changesets to retrieve the user_name_token for authentication.
       - Retrieve the header from the changeset.
       - Retrieve the security changeset from the header.
       - Retrieve the user_name_token changeset from the security data.
    4. Extract the data_fetch changeset from the body of the main changeset.
       - From data_fetch, extract the pagination changeset.
    5. Output debugging information by inspecting the hotel_code, pagination limit, and offset.
    6. Based on the validity of the user_name_token:
         a. If valid, extract the user credentials (user_name and password) and attempt authentication.
         b. Upon successful authentication, validate pagination and data_fetch changesets.
         c. If these changesets are valid, fetch messages using the extracted hotel_code, limit, and offset.
         d. Build a successful XML response with status 200; otherwise, build an error response (403) with collected errors.
         e. If authentication fails, build an XML response indicating an authorization error.
         f. If the user_name_token is invalid, build a forbidden response (403) with the relevant validation errors.
    7. Set the response content type to XML and send the response back to the client.
  """
  def get_list(conn, _params) do
    # Parse the cleaned XML request stored in the connection's private data.
    request = conn.private[:cleaned_body] |> PrivateDataFetchRequest.parse()

    # Build a changeset for the GetRates schema using the parsed request.
    set = %GetRates{} |> DataFetchForm.changeset(request)

    # Extract the nested user_name_token changeset from the main changeset.
    # The process involves:
    #   a) Extracting the header changeset.
    #   b) From the header, extracting the security changeset.
    #   c) Finally, retrieving the user_name_token changeset from security.
    user_name_token =
      set
      |> Changeset.get_change(:header)
      |> Changeset.get_change(:security)
      |> Changeset.get_change(:user_name_token)

    # Extract the data_fetch changeset from the body of the main changeset.
    # This contains additional data required for fetching rates.
    data_fetch =
      set
      |> Changeset.get_change(:body)
      |> Changeset.get_change(:data_fetch)

    # From the data_fetch changeset, extract the pagination changeset.
    # This holds information about how to paginate the results.
    pagination = data_fetch |> Changeset.get_change(:pagination)

    # Build the response based on the validity of the user_name_token changeset.
    response =
      if user_name_token.valid? do
        # Extract user credentials from the user_name_token changeset.
        # These credentials will be used to verify the user's identity.
        user_name = Changeset.get_change(user_name_token, :user_name)  # Retrieve the 'user_name'
        password = Changeset.get_change(user_name_token, :password)    # Retrieve the 'password'

        # Attempt to authenticate the user with the provided credentials.
        # The authentication function checks the credentials against the stored records.
        case Accounts.authenticate_user(user_name, password) do
          {:ok, user} ->
            # If authentication is successful, further validate the pagination and data_fetch changesets.
            if pagination.valid? do
              if data_fetch.valid? do
                # If both nested changesets are valid, fetch the messages based on hotel_code, limit, and offset.
                messages =
                  OtaHotelRatePlanNotifRQ.get_rate_plan_by_hotel_code(
                    Changeset.get_change(data_fetch, :hotel_code),
                    user.customer_code,
                    Changeset.get_change(pagination, :limit),
                    Changeset.get_change(pagination, :offset)
                  )
                # Build a successful response with a 200 status and include the fetched messages.
                %{status: 200, body: GetRatesResponse.build(messages, [])}
              else
                # If the data_fetch changeset is invalid, collect its errors and build a 403 response.
                %{status: 403, body: GetRatesResponse.build([], data_fetch |> collect_errors)}
              end
            else
              # If the pagination changeset is invalid, collect its errors and build a 403 response.
              %{status: 403, body: GetRatesResponse.build([], pagination |> collect_errors)}
            end

          {:error, _unauthorized} ->
            # If user authentication fails, build an authorization error response.
            # The response includes an error code indicating the authentication failure.
            auth_error = "491|Authorization error"
            %{status: 200, body: GetRatesResponse.build([], [auth_error: auth_error])}
        end
      else
        # If the user_name_token changeset is invalid, collect its errors and build a 403 forbidden response.
        %{status: 403, body: GetRatesResponse.build([], user_name_token |> collect_errors)}
      end

    # Set the response content type to XML and send the response with the determined status and body.
    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(response.status, response.body)
  end

  @doc """
  Handles the OTA rate plan notification request (OTA_HotelRatePlanNotifRQ).

  This function performs the following:
    1. Parses the incoming XML message from the request body.
    2. Generates a unique UUID to tag the request.
    3. Constructs a changeset for the rate message using the parsed data.
    4. Extracts the OTA-specific rate plan notification request from the changeset.
    5. Retrieves the user_name_token changeset from the header for authentication.
    6. Attempts to authenticate the user with the credentials found in user_name_token.
    7. If authentication is successful, processes the rate request within a transaction.
    8. Constructs and returns an XML response based on the result of the processing.
  """
  def update(conn, _params) do
    # Parse the incoming XML message.
    message = conn.private[:cleaned_body] |> PublicRateParserRequest.parse()

    # Generate a unique identifier (UUID) for this request.
    uuid4 = UUID.uuid4()

    # Build a changeset for the rate message using the parsed XML data.
    set = %UpdateRate{} |> HotelRatePlanNotifRqForm.changeset(message)

    # Extract the OTA rate plan notification request from the body of the changeset.
    ota =
      set
      |> Changeset.get_change(:body)               # Get the 'body' change from the changeset.
      |> Changeset.get_change(:ota_hotel_rate_plan_notif_rq)  # Retrieve the OTA-specific request.

    # Extract the user_name_token changeset for authentication purposes.
    user_name_token =
      set
      |> Changeset.get_change(:header)     # Retrieve the header changeset.
      |> Changeset.get_change(:security)     # From the header, get the security changeset.
      |> Changeset.get_change(:user_name_token)  # From the security changeset, retrieve the user_name_token.

    # Build the response by checking the validity of user_name_token.
    response =
      if user_name_token.valid? do
        # Extract the user credentials from user_name_token.
        user_name = Changeset.get_change(user_name_token, :user_name)  # Retrieve the 'user_name'
        password = Changeset.get_change(user_name_token, :password)    # Retrieve the 'password'

        # Attempt to authenticate the user using the provided credentials.
        case Accounts.authenticate_user(user_name, password) do
          {:ok, user} ->
            process_update(ota |> Changeset.change(customer_code: user.customer_code), message, uuid4)
          {:error, _unauthorized} ->
            # If authentication fails, prepare a response with an authorization error.
            auth_error = "491|Authorization error"
            %{
              status: 401,
              body: OtaResponse.build(message, uuid4, "OTA_HotelRatePlanNotifRS", [database: auth_error]),
              id: nil,
              customer_code: nil
            }
        end
      else
        # If the user_name_token changeset is invalid, collect its errors and return a forbidden response.
        %{
          status: 403,
          body: OtaResponse.build(message, uuid4, "OTA_HotelRatePlanNotifRS", user_name_token |> collect_errors),
          id: nil,
          customer_code: nil
        }
      end

    # Asynchronously build and insert an audit message into the database.
    build_message(conn, response, set, uuid4) |> create_message_async(response.id)

    # Set the response content type to XML and send the constructed response.
    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(response.status, response.body)
  end

  @doc """
  Recursively collects all validation errors from a changeset and its nested changesets.

  Returns a flattened list of error tuples in the format:
    [{field, error_message}, ...]
  """
  defp collect_errors(%Changeset{errors: errors, changes: changes}) do
    error_list = Enum.map(errors, fn {field, {message, _}} -> {field, message} end)

    nested_errors =
      Enum.flat_map(changes, fn
        {_, %Changeset{} = nested_changeset} -> collect_errors(nested_changeset)
        {_, changesets} when is_list(changesets) -> Enum.flat_map(changesets, &collect_errors/1)
        _ -> []
      end)

    error_list ++ nested_errors
  end

  @doc """
  Processes the OTA rate plan notification request within a database transaction.

  Steps:
    1. Collect all validation errors from the OTA changeset.
    2. If the OTA changeset is valid, perform a database transaction using Ecto.Multi
       to insert the OTA rate plan notification request.
    3. Based on the transaction result, build and return an XML response:
         - 200 OK if successful.
         - 500 Internal Server Error if the transaction fails.
         - 400 Bad Request if the OTA changeset is invalid.
  """
  defp process_update(ota, message, uuid4) do
    # Collect any validation errors from the OTA changeset.
    all_errors = collect_errors(ota)

    response =
      if ota.valid? do
        case Repo.transaction(Multi.new() |> Multi.insert(:ota_hotel_rate_plan_notif_rq, ota)) do
          {:ok, %{ota_hotel_rate_plan_notif_rq: result}} ->
            %{
              status: 200,
              body: OtaResponse.build(message, uuid4, "OTA_HotelRatePlanNotifRS", all_errors),
              id: result.id,
              customer_code: result.customer_code
            }
          {:error, _failed_operation, _failed_value, _changes_so_far} ->
            db_error = "Database transaction failed"
            %{
              status: 500,
              body: OtaResponse.build(message, uuid4, "OTA_HotelRatePlanNotifRS", [database: db_error]),
              id: nil,
              customer_code: nil
            }
        end
      else
        %{
          status: 400,
          body: OtaResponse.build(message, uuid4, "OTA_HotelRatePlanNotifRS", all_errors),
          id: nil,
          customer_code: nil
        }
      end

    response
  end

  @doc """
  Builds a message map for auditing purposes to be inserted into the database.

  The message map is constructed by:
    - Extracting nested changesets (e.g., user_name_token for authentication data, OTA request details).
    - Combining these values with additional information like the response, raw request body, and a unique identifier.
  """
  defp build_message(conn, response, set, uuid4) do
    # Extract the user_name_token changeset, which contains authentication information.
    user_name_token =
      set
      |> Changeset.get_change(:header)
      |> Changeset.get_change(:security)
      |> Changeset.get_change(:user_name_token)

    # Extract the header changeset for additional metadata.
    header = set |> Changeset.get_change(:header)

    # Extract the OTA rate plan notification request from the changeset's body.
    ota =
      set
      |> Changeset.get_change(:body)
      |> Changeset.get_change(:ota_hotel_rate_plan_notif_rq)

    %{
      entity_id: response.id,  # The ID from the response, used as the entity identifier.
      hotel_code: ota
                  |> Changeset.get_change(:rate_plans)  # Extract the rate_plans data from the OTA request.
                  |> Changeset.get_change(:hotel_code),  # Retrieve the hotel_code from rate_plans.
      user_name: user_name_token |> Changeset.get_change(:user_name),  # Extract the user_name from the user_name_token changeset.
      time_stamp: ota |> Changeset.get_change(:time_stamp),  # Retrieve the time_stamp from the OTA request.
      internal_id: header |> Changeset.get_change(:message_id),  # Get the internal message_id from the header.
      outside_id: uuid4,  # Unique external identifier for the request.
      customer_code:  response.customer_code,
      request: conn.private[:cleaned_body],  # The raw cleaned XML request body.
      response: response.body,  # The XML response body.
      rate: true,  # Flag indicating that this is a rate-related message.
      error: if(response.status == 200, do: false, else: true),  # Set error flag based on response status.
      active: if(response.status == 200, do: true, else: false)   # Set active flag based on response status.
    }
  end

  @doc """
  Asynchronously creates a message record and inserts it into the database.

  This function:
    1. Starts an asynchronous task.
    2. Logs the start of the task.
    3. Builds a changeset for the Message schema using the provided attributes.
    4. Attempts to insert the message into the repository.
    5. Logs whether the insertion was successful or if an error occurred.
  """
  defp create_message_async(attr, ota_hotel_rate_plan_notif_rq_id) do
    Task.start(fn ->
      Logger.info("Task started")
      try do
        case %Message{}
             |> Message.changeset(attr)
             |> Repo.insert() do
          {:ok, message} ->
            update_ota_record(%{outside_id: message.outside_id, message_id: message.id}, ota_hotel_rate_plan_notif_rq_id)
            Logger.info("Message inserted successfully: #{inspect(message)}")
          {:error, changeset} ->
            Logger.error("Error inserting message: #{inspect(changeset)}")
        end
      rescue
        exception ->
          Logger.error("Task encountered exception: #{inspect(exception)}")
      end
      Logger.info("Task finished")
    end)
  end

  defp update_ota_record(attrs, ota_hotel_rate_plan_notif_rq_id) do
    ota = Repo.get(Ari.Schemas.Rate.OtaHotelRatePlanNotifRQ, ota_hotel_rate_plan_notif_rq_id)
    result = ota
    |> Ari.Schemas.Rate.OtaHotelRatePlanNotifRQ.changeset(attrs)
    |> Repo.update()
    IO.inspect(result)
  end
end
