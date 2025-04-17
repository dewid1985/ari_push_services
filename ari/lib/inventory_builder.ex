defmodule InventoryBuilder do
  alias XmlBuilder

  @doc """
  Main function that builds the complete XML document
  """
  def build(messages, errors) do
    error_elements = build_error_elements(errors)
    success_element = XmlBuilder.element("ota:Success", [])

    body_elements = cond do
      error_elements != [] ->
        elements = [XmlBuilder.element("ota:Errors", error_elements)]
        [XmlBuilder.element("ota:GetRatesResponse", elements)]
      true ->
        [XmlBuilder.element("ota:GetRatesResponse", [success_element, messages|> build_messages()])]
    end

    XmlBuilder.document([ # Create an XML document
      XmlBuilder.element(
        "soap:Envelope",  # Root SOAP envelope element
        %{
          "xmlns:soap" => "http://www.w3.org/2003/05/soap-envelope",  # SOAP namespace
          "xmlns:ota" => "http://www.opentravel.org/OTA/2003/05",     # OTA namespace for the message structure
          "xmlns:wsa" => "http://www.w3.org/2005/08/addressing"       # WSA namespace
        },
        [
          XmlBuilder.element("soap:Body", body_elements)  # Add SOAP body containing the OTA messages
        ]
      )
    ])
    |> XmlBuilder.generate(format: :indented)  # Generate XML with indentation for readability
  end

  # Function to build the OTA messages inside the SOAP body
  defp build_messages(messages) do

    success_element = XmlBuilder.element("ota:Success", [])

    Enum.map(messages, fn message ->
      XmlBuilder.element(
        "ota:OTA_HotelRatePlanNotifRQ",  # Main element for OTA message
        %{
          "Version": message.version,              # OTA version
          "MessageContentCode": message.message_content_code,  # Message content code
          "TimeStamp": message.time_stamp |> DateTime.to_iso8601()  # Time of the message in ISO8601 format
        },
        [
          build_rate_plans(message.rate_plans)  # Build nested rate plans element
        ]
      )
    end)
  end

  # Function to build the RatePlans element containing multiple rate plans
  defp build_rate_plans(rate_plans) do
    XmlBuilder.element(
      "ota:RatePlans",
      %{
        "HotelCode" => rate_plans.hotel_code  # Add hotel code as an attribute
      }
      |> filter_attributes,  # Filter out any attributes with nil values
      Enum.map(rate_plans.rate_plan, &build_rate_plan/1)  # Map over the list of rate plans and build each
    )
  end

  # Function to build individual RatePlan element
  defp build_rate_plan(rate_plan) do
    XmlBuilder.element(
      "ota:RatePlan",
      %{
        "Start" => rate_plan.start,          # Start date of the rate plan
        "End" => rate_plan.end,              # End date of the rate plan
        "RatePlanCode" => rate_plan.rate_plan_code,  # Rate plan code
        "RatePlanNotifType" => rate_plan.rate_plan_notif_type  # Notification type for the rate plan
      }
      |> filter_attributes,  # Filter attributes to remove nil values
      [
        build_destination_systems_code(rate_plan.destination_systems_code),  # Add destination systems code
        build_rates(rate_plan.rates),  # Add rates element
        build_unique_id(rate_plan.unique_id)  # Add unique ID for the rate plan
      ]
    )
  end

  # Function to build DestinationSystemsCode element, which contains multiple codes
  defp build_destination_systems_code(build_destinations_system) do
    XmlBuilder.element(
      "ota:DestinationSystemsCode",
      Enum.map(
        build_destinations_system,  # Map over each destination system code
        &build_destination_system_code/1  # Build individual destination system code elements
      )
    )
  end

  # Function to build an individual DestinationSystemCode element
  defp build_destination_system_code(build_destination_system) do
    XmlBuilder.element(
      "ota:DestinationSystemCode",
      build_destination_system.text  # Add the text value of the destination system code
    )
  end

  # Function to build the Rates element, which contains multiple rate elements
  defp build_rates(rates) do
    XmlBuilder.element(
      "ota:Rates",
      Enum.map(
        rates,  # Map over each rate in the list
        &build_rate/1  # Build each individual rate element
      )
    )
  end

  # Function to build an individual Rate element
  defp build_rate(rate) do
    XmlBuilder.element(
      "ota:Rate",
      %{
        "Mon" => to_string(rate.mon),  # Rate for Monday
        "Tue" => to_string(rate.tue),  # Rate for Tuesday
        "Weds" => to_string(rate.weds),  # Rate for Wednesday
        "Thur" => to_string(rate.thur),  # Rate for Thursday
        "Fri" => to_string(rate.fri),  # Rate for Friday
        "Sat" => to_string(rate.sat),  # Rate for Saturday
        "Sun" => to_string(rate.sun),  # Rate for Sunday
        "CurrencyCode" => rate.currency_code,  # Currency code for the rate
        "InvTypeCode" => rate.inv_type_code,  # Inventory type code
        "MaxLOS" => rate.max_los,  # Maximum length of stay for this rate
        "MinLOS" => rate.min_los,  # Minimum length of stay for this rate
        "RateTimeUnit" => rate.rate_time_unit  # Time unit for the rate (e.g., night, day)
      }
      |> filter_attributes,  # Filter attributes to remove any nil values
      [
        build_base_by_guest_amts(rate.base_by_guest_amts)  # Add base amounts by guest
      ]
    )
  end

  # Function to build BaseByGuestAmts element, which contains multiple BaseByGuestAmt elements
  defp build_base_by_guest_amts(base_by_guest_amts) do
    XmlBuilder.element(
      "ota:BaseByGuestAmts",
      Enum.map(
        base_by_guest_amts,  # Map over guest amounts
        &build_base_by_guest_amt/1  # Build individual BaseByGuestAmt elements
      )
    )
  end

  # Function to build an individual BaseByGuestAmt element
  defp build_base_by_guest_amt(base_by_guest_amt) do
    XmlBuilder.element(
      "ota:BaseByGuestAmt",
      %{
        "AmountBeforeTax" => base_by_guest_amt.amount_before_tax,  # Amount before tax
        "AmountAfterTax" => base_by_guest_amt.amount_after_tax,    # Amount after tax
        "NumberOfGuests" => base_by_guest_amt.number_of_guests,    # Number of guests
        "AgeQualifyingCode" => base_by_guest_amt.age_qualifying_code,  # Age qualifying code
        "MinAge" => base_by_guest_amt.min_age,  # Minimum age (optional)
        "MaxAge" => base_by_guest_amt.max_age   # Maximum age (optional)
      }
      |> filter_attributes,  # Remove nil attributes
      []
    )
  end

  # Function to build the UniqueID element
  defp build_unique_id(unique_id) do
    XmlBuilder.element(
      "ota:UniqueID",
      %{
        "Type" => unique_id.type,  # Type of the unique ID
        "ID" => unique_id.code     # The actual unique ID
      }
      |> filter_attributes,  # Remove any nil values from the attributes
      []
    )
  end

  # Helper function to filter out attributes that have nil values
  defp filter_attributes(attributes) do
    Enum.reject(attributes, fn {_, v} -> is_nil(v) end)  # Reject any attributes where the value is nil
  end

  # Private function to generate XML elements for any errors.
  # It creates `<ota:Error>` elements based on the list of errors passed into the function.
  defp build_error_elements(errors) do
    # Iterate over the errors and build XML elements for each error.
    Enum.map(errors, fn
      # For errors represented as a tuple of {field, message}, where message is a string.
      {field, message} when is_binary(message) ->
        # Split the message into error code and short description if separated by '|'.
        case String.split(message, "|", parts: 2) do
          [code, short_error] ->
            # Build an error element with a specific code and short text.
            XmlBuilder.element("ota:Error", %{
              Type: "3",  # The error type (3 indicates a generic error).
              Code: code,  # The specific error code.
              ShortText: short_error  # The short description of the error.
            })
          _ ->
            # If message doesn't split into code and description, use default error format.
            XmlBuilder.element("ota:Error", %{
              Type: "1",  # General error type (1 indicates a validation error).
              Code: "450",  # Default error code.
              ShortText: Atom.to_string(field) <> " : " <> message  # Field name and error message combined.
            })
        end

      # For errors where the message is not a string (e.g., when the message is an atom or other type).
      {field, _} ->
        # Build a default error element using the field name.
        XmlBuilder.element("ota:Error", %{
          Type: "3",  # Generic error type.
          Code: "320",  # Default error code for unspecified error types.
          ShortText: Atom.to_string(field)  # Use the field name as the error description.
        })

      # Catch-all case for unknown error formats.
      _ ->
        # Default unknown error element.
        XmlBuilder.element("ota:Error", %{
          Type: "3",  # Generic error type.
          Code: "Unknown",  # Error code when no specific code is provided.
          ShortText: "Unknown"  # Default error message.
        })
    end)
  end
end
