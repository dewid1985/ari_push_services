defmodule GetInventoriesResponse do
  alias XmlBuilder

  @doc """
  Main function that builds the complete XML document.
  Takes two arguments:
  - `messages`: A list of OTA messages to be included in the SOAP body.
  - `errors`: A list of errors that will be added to the document if any exist.
  """
  def build(messages, errors) do
    # Build the list of error elements from the errors.
    error_elements = build_error_elements(errors)

    # Create the Success element for successful responses.
    success_element = XmlBuilder.element("ota:Success", [])

    # Conditionally build the body elements based on whether there are errors or not.
    body_elements = cond do
      error_elements != [] ->
        # If there are errors, wrap them inside the "ota:Errors" element.
        elements = [XmlBuilder.element("ota:Errors", error_elements)]
        # Wrap the error elements in a "ota:GetRatesResponse" element.
        [XmlBuilder.element("ota:GetRatesResponse", elements)]
      true ->
        # If there are no errors, wrap the success element and messages in the response.
        [XmlBuilder.element("ota:GetRatesResponse", [success_element, messages |> build_messages()])]
    end

    # Create the SOAP envelope with proper namespaces.
    XmlBuilder.document([
      XmlBuilder.element(
        "soap:Envelope",
        %{
          "xmlns:soap" => "http://www.w3.org/2003/05/soap-envelope",
          "xmlns:ota" => "http://www.opentravel.org/OTA/2003/05",
          "xmlns:wsa" => "http://www.w3.org/2005/08/addressing"
        },
        [
          XmlBuilder.element("soap:Body", body_elements)
        ]
      )
    ])
    |> XmlBuilder.generate(format: :none)
  end

  @doc """
  Builds the OTA messages for the SOAP body.
  Each message is transformed into an XML element with its associated inventories.
  """
  defp build_messages(messages) do
    Enum.map(messages, fn message ->
      XmlBuilder.element(
        "ota:OTA_HotelInvCountNotifRQ",
        %{
          "Version": message.version,
          "TimeStamp": message.time_stamp |> DateTime.to_iso8601()
        },
        [
          message.inventories |> build_inventories
        ]
      )
    end)
  end

  @doc """
  Builds the Inventories XML element.
  This function creates an "ota:Inventories" element with a HotelCode attribute.
  It includes:
    - A list of inventory entries built by `build_inventory/1`.
    - A unique identifier built by `build_unique_id/1`.
  """
  defp build_inventories(inventories) do
    XmlBuilder.element(
      "ota:Inventories",
      %{
        "HotelCode" => inventories.hotel_code
      }
      |> filter_attributes,
      [
        inventories.inventory |> Enum.map(&build_inventory/1),
        inventories.unique_id |> build_unique_id
      ]
    )
  end

  @doc """
  Builds an individual Inventory XML element.
  This function constructs an "ota:Inventory" element that includes:
    - The status application control details via `build_status_application_control/1`.
    - The inventory counts via `build_inv_counts/1`.
  """
  defp build_inventory(inventory) do
    XmlBuilder.element(
      "ota:Inventory",
      [
        inventory.status_application_control |> build_status_application_control,
        inventory.inv_counts |> build_inv_counts
      ]
    )
  end

  @doc """
  Builds the StatusApplicationControl XML element.
  This element contains attributes like Start, End, and InvTypeCode, and includes
  nested destination system codes built by `build_destination_systems_code/1`.
  """
  def build_status_application_control(status_application_control) do
    IO.inspect(status_application_control)
    XmlBuilder.element(
      "ota:StatusApplicationControl",
      %{
        "Start" => status_application_control.start,
        "End" => status_application_control.end,
        "InvTypeCode" => status_application_control.inv_type_code
      }
      |> filter_attributes,
      [
        status_application_control.distination_system_codes |> build_destination_systems_code
      ]
    )
  end

  @doc """
  Builds the InvCounts XML element, which encapsulates a list of inventory count entries.
  """
  defp build_inv_counts(inv_counts) do
    XmlBuilder.element(
      "ota:InvCounts",
      [
        inv_counts.inv_count |> Enum.map(&build_inv_count/1)
      ]
    )
  end

  @doc """
  Builds an individual InvCount XML element representing a single inventory count.
  """
  defp build_inv_count(inv_count) do
    XmlBuilder.element(
      "ota:InvCount",
      %{
        "CountType" => inv_count.count_type,
        "Count" => inv_count.count
      }
    )
  end

  @doc """
  Builds the DestinationSystemCodes XML element.
  It wraps individual DestinationSystemCode elements for each provided system code.
  """
  defp build_destination_systems_code(build_destinations_system) do
    XmlBuilder.element(
      "ota:DestinationSystemCodes",
      build_destinations_system |> Enum.map(&build_destination_system_code/1)
    )
  end

  @doc """
  Builds an individual DestinationSystemCode XML element.
  The text content of the element is set to the provided destination system code.
  """
  defp build_destination_system_code(build_destination_system) do
    XmlBuilder.element(
      "ota:DestinationSystemCode",
      build_destination_system.text
    )
  end

  @doc """
  Builds the UniqueID XML element.
  It includes attributes for the type and the code of the unique identifier.
  """
  defp build_unique_id(unique_id) do
    XmlBuilder.element(
      "ota:UniqueID",
      %{
        "Type" => unique_id.type,
        "ID" => unique_id.code
      }
      |> filter_attributes,
      []
    )
  end

  @doc """
  Filters out attributes with nil values from the given map.
  This prevents XML elements from having attributes with nil values.
  """
  defp filter_attributes(attributes) do
    Enum.reject(attributes, fn {_, v} -> is_nil(v) end)
  end

  @doc """
  Builds error elements for the XML document.
  Each error is transformed into an XML element with appropriate attributes.
  """
  defp build_error_elements(errors) do
    Enum.map(errors, fn
      {field, message} when is_binary(message) ->
        case String.split(message, "|", parts: 2) do
          [code, short_error] ->
            XmlBuilder.element("ota:Error", %{
              Type: "3",
              Code: code,
              ShortText: short_error
            })
          _ ->
            XmlBuilder.element("ota:Error", %{
              Type: "1",
              Code: "450",
              ShortText: Atom.to_string(field) <> " : " <> message
            })
        end

      {field, _} ->
        XmlBuilder.element("ota:Error", %{
          Type: "3",
          Code: "320",
          ShortText: Atom.to_string(field)
        })

      _ ->
        XmlBuilder.element("ota:Error", %{
          Type: "3",
          Code: "Unknown",
          ShortText: "Unknown"
        })
    end)
  end
end
