defmodule Ari.Contexts.Availability.OtaHotelAvailNotifRq do
  import Ecto.Query
  alias Ari.Repo
  alias Ari.Schemas.Availability.{OtaHotelAvailNotifRq, AvailStatusMessages}

  @doc """
  Returns all availability notifications for the given hotel_code.
  """
  def get_availability_by_hotel_code(hotel_code, customer_code) do
    base_query(hotel_code, customer_code)
    |> Repo.all()
  end

  @doc """
  Returns availability notifications for the given hotel_code limited by the given limit.
  """
  def get_availability_by_hotel_code(hotel_code, customer_code,  limit) do
    base_query(hotel_code, customer_code)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Returns availability notifications for the given hotel_code with pagination using limit and offset.
  """
  def get_availability_by_hotel_code(hotel_code, customer_code, limit, offset) do
    base_query(hotel_code, customer_code)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  # Private function: Constructs the base query for retrieving availability notifications.
  defp base_query(hotel_code, customer_code) do
    from notif in OtaHotelAvailNotifRq,
         join: messages in AvailStatusMessages, on: messages.id == messages.ota_hotel_avail_notif_rq_id,
         where: messages.hotel_code == ^hotel_code and notif.customer_code == ^customer_code,
         preload: [
           avail_status_messages: {messages,
             [avail_status_message: [
               status_application_control: [:destination_system_codes],
               unique_id: [],
               restriction_status: [],
               lengths_of_stay: [:length_of_stay]
             ]]
           }
         ],
         order_by: [asc: notif.time_stamp]
  end
end
