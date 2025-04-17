defmodule GetRatesResponse do
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
        "soap:Envelope",  # Root element for the SOAP message.
        %{
          "xmlns:soap" => "http://www.w3.org/2003/05/soap-envelope",  # Namespace for SOAP.
          "xmlns:ota" => "http://www.opentravel.org/OTA/2003/05",     # Namespace for OTA.
          "xmlns:wsa" => "http://www.w3.org/2005/08/addressing"       # Namespace for WSA (Web Services Addressing).
        },
        [
          XmlBuilder.element("soap:Body", body_elements)  # SOAP body containing OTA response elements.
        ]
      )
    ])
    |> XmlBuilder.generate(format: :none)  # Generate XML with indentation for readability.
  end

  # Function to build OTA messages for the SOAP body.
  # Takes a list of `messages` and transforms them into XML elements.
  defp build_messages(messages) do
    success_element = XmlBuilder.element("ota:Success", [])  # Create a success element.

    Enum.map(messages, fn message ->
      # Create an OTA Hotel Rate Plan Notification element with attributes.
      XmlBuilder.element(
        "ota:OTA_HotelRatePlanNotifRQ",
        %{
          "Version": message.version,  # Version of the OTA message.
          "MessageContentCode": message.message_content_code,  # Content code of the message.
          "TimeStamp": message.time_stamp |> DateTime.to_iso8601()  # Message timestamp in ISO 8601 format.
        },
        [
          build_rate_plans(message.rate_plans)  # Add nested rate plans inside the message.
        ]
      )
    end)
  end

  # Function to build RatePlans element containing multiple rate plans.
  # Takes `rate_plans` and creates a parent "ota:RatePlans" element with its attributes.
  defp build_rate_plans(rate_plans) do
    XmlBuilder.element(
      "ota:RatePlans",
      %{
        "HotelCode" => rate_plans.hotel_code  # Add the hotel code as an attribute.
      }
      |> filter_attributes,  # Filter out any attributes that are nil.
      Enum.map(rate_plans.rate_plan, &build_rate_plan/1)  # Map over the list of rate plans and build each.
    )
  end

  # Function to build an individual RatePlan element.
  # Takes a `rate_plan` and constructs the XML element for it.
  defp build_rate_plan(rate_plan) do
    XmlBuilder.element(
      "ota:RatePlan",
      %{
        "Start" => rate_plan.start,  # Start date of the rate plan.
        "End" => rate_plan.end,  # End date of the rate plan.
        "RatePlanCode" => rate_plan.rate_plan_code,  # Unique code for the rate plan.
        "RatePlanNotifType" => rate_plan.rate_plan_notif_type  # Type of notification (e.g., new, update).
      }
      |> filter_attributes,  # Filter out nil values from attributes.
      [
        build_destination_systems_code(rate_plan.destination_systems_code),  # Build nested DestinationSystemsCode element.
        build_rates(rate_plan.rates),  # Add nested Rates element.
        build_unique_id(rate_plan.unique_id)  # Add unique ID for the rate plan.
      ]
    )
  end

  # Function to build DestinationSystemsCode element.
  # Takes a list of `build_destinations_system` and maps each into a DestinationSystemCode element.
  defp build_destination_systems_code(build_destinations_system) do
    XmlBuilder.element(
      "ota:DestinationSystemsCode",
      Enum.map(
        build_destinations_system,  # Iterate over each destination system code.
        &build_destination_system_code/1  # Build individual DestinationSystemCode elements.
      )
    )
  end

  # Function to build an individual DestinationSystemCode element.
  # Takes a `build_destination_system` and returns a corresponding XML element.
  defp build_destination_system_code(build_destination_system) do
    XmlBuilder.element(
      "ota:DestinationSystemCode",
      build_destination_system.text  # Set the text value of the destination system code.
    )
  end

  # Function to build Rates element containing multiple Rate elements.
  # Takes a list of `rates` and constructs the parent "ota:Rates" element.
  defp build_rates(rates) do
    XmlBuilder.element(
      "ota:Rates",
      Enum.map(
        rates,  # Iterate over each rate.
        &build_rate/1  # Build individual Rate elements.
      )
    )
  end

  # Function to build an individual Rate element.
  # Takes a `rate` and constructs its corresponding XML element with attributes.
  defp build_rate(rate) do
    XmlBuilder.element(
      "ota:Rate",
      %{
        "Mon" => to_string(rate.mon),  # Rate for Monday.
        "Tue" => to_string(rate.tue),  # Rate for Tuesday.
        "Weds" => to_string(rate.weds),  # Rate for Wednesday.
        "Thur" => to_string(rate.thur),  # Rate for Thursday.
        "Fri" => to_string(rate.fri),  # Rate for Friday.
        "Sat" => to_string(rate.sat),  # Rate for Saturday.
        "Sun" => to_string(rate.sun),  # Rate for Sunday.
        "CurrencyCode" => rate.currency_code,  # Currency code for the rate.
        "InvTypeCode" => rate.inv_type_code,  # Inventory type code.
        "MaxLOS" => rate.max_los,  # Maximum length of stay.
        "MinLOS" => rate.min_los,  # Minimum length of stay.
        "RateTimeUnit" => rate.rate_time_unit  # Time unit for the rate (e.g., night, day).
      }
      |> filter_attributes,  # Remove nil attributes.
      [
        build_base_by_guest_amts(rate.base_by_guest_amts)  # Add BaseByGuestAmts element.
      ]
    )
  end

  # Function to build BaseByGuestAmts element containing multiple BaseByGuestAmt elements.
  defp build_base_by_guest_amts(base_by_guest_amts) do
    XmlBuilder.element(
      "ota:BaseByGuestAmts",
      Enum.map(
        base_by_guest_amts,  # Map over each guest amount.
        &build_base_by_guest_amt/1  # Build individual BaseByGuestAmt elements.
      )
    )
  end

  # Function to build an individual BaseByGuestAmt element.
  # Takes a `base_by_guest_amt` and builds its corresponding XML element.
  defp build_base_by_guest_amt(base_by_guest_amt) do
    XmlBuilder.element(
      "ota:BaseByGuestAmt",
      %{
        "AmountBeforeTax" => base_by_guest_amt.amount_before_tax,  # Amount before tax.
        "AmountAfterTax" => base_by_guest_amt.amount_after_tax,  # Amount after tax.
        "NumberOfGuests" => base_by_guest_amt.number_of_guests,  # Number of guests.
        "AgeQualifyingCode" => base_by_guest_amt.age_qualifying_code,  # Age qualification code.
        "MinAge" => base_by_guest_amt.min_age,  # Minimum age (optional).
        "MaxAge" => base_by_guest_amt.max_age  # Maximum age (optional).
      }
      |> filter_attributes,  # Remove nil attributes.
      []
    )
  end

  # Function to build the UniqueID element.
  # Takes a `unique_id` and constructs its corresponding XML element.
  defp build_unique_id(unique_id) do
    XmlBuilder.element(
      "ota:UniqueID",
      %{
        "Type" => unique_id.type,  # Type of the unique ID.
        "ID" => unique_id.code  # The actual unique ID.
      }
      |> filter_attributes,  # Remove nil attributes.
      []
    )
  end

  # Helper function to filter out attributes with nil values.
  # This ensures that the XML elements don't contain attributes with nil values.
  defp filter_attributes(attributes) do
    Enum.reject(attributes, fn {_, v} -> is_nil(v) end)  # Remove any attributes with nil values.
  end

  # Private function to generate XML elements for errors.
  # Takes a list of `errors` and builds a list of `<ota:Error>` elements.
  defp build_error_elements(errors) do
    # Iterate over the list of errors and build an XML element for each.
    Enum.map(errors, fn
      # Case when the error is a tuple {field, message} where message is a string.
      {field, message} when is_binary(message) ->
        case String.split(message, "|", parts: 2) do
          [code, short_error] ->
            # Create an error element with a specific error code and description.
            XmlBuilder.element("ota:Error", %{
              Type: "3",  # Error type 3 indicates a generic error.
              Code: code,  # The specific error code.
              ShortText: short_error  # Short description of the error.
            })
          _ ->
            # If no code is provided, default to a general error format.
            XmlBuilder.element("ota:Error", %{
              Type: "1",  # Error type 1 indicates a validation error.
              Code: "450",  # Default validation error code.
              ShortText: Atom.to_string(field) <> " : " <> message  # Combine field name and error message.
            })
        end

      # Case when the error message is not a string (e.g., it's an atom).
      {field, _} ->
        # Build a default error element for this field.
        XmlBuilder.element("ota:Error", %{
          Type: "3",  # Generic error type.
          Code: "320",  # Default error code for this scenario.
          ShortText: Atom.to_string(field)  # Use the field name as the short description.
        })

      # Catch-all for any other unknown error formats.
      _ ->
        # Default unknown error element.
        XmlBuilder.element("ota:Error", %{
          Type: "3",  # Generic error type.
          Code: "Unknown",  # Error code indicating an unknown error.
          ShortText: "Unknown"  # Default error description.
        })
    end)
  end
end
