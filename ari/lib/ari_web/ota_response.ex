defmodule AriWeb.OtaResponse do
  alias XmlBuilder  # Using XmlBuilder to build XML elements.

  # Public function to build the OTA (Open Travel Alliance) response XML.
  # This function generates a complete SOAP envelope with a header and a body, based on the given message, UUID, response name, and a list of errors.
  def build(message, uuid4, ota_response_name, errors) do

    # Step 1: Extract the necessary header values from the message and the provided UUID.
    # These values include message-specific IDs and addressing details.
    header_data = extract_header_values(message, uuid4)

    # Step 2: Construct the SOAP header using the extracted values.
    # This includes message ID, recipient, action, and reply-to address information.
    header = build_header(
      header_data.uuid4,            # Generated UUID for the current message.
      header_data.message_id,       # The message ID this response relates to.
      header_data.to,               # The recipient of the message.
      header_data.action,           # The action associated with the message.
      header_data.address           # The reply-to address for responses.
    )

    # Step 3: Create XML elements representing any errors present in the response.
    # If there are no errors, this will be an empty list.
    error_elements = build_error_elements(errors)

    # Step 4: Create a success element for the response if no errors are present.
    # This element indicates a successful response in OTA messages.
    success_element = XmlBuilder.element("ota:Success", [])

    # Step 5: Extract additional optional data from the message body, such as version and message content code.
    version = get_in(message, [:body, :message, :version])
    message_content_code = get_in(message, [:body, :message, :message_content_code])

    # Step 6: Prepare basic response attributes, including a timestamp.
    # The timestamp is generated using the current UTC time in ISO8601 format.
    response_attributes = %{
      "TimeStamp" => DateTime.utc_now() |> DateTime.to_iso8601()  # Timestamp of the response.
    }

    # Step 7: Conditionally add the version to the response attributes if it's present.
    response_attributes =
      if version != nil and version != "" do
        Map.put(response_attributes, "Version", version)  # Add version if available.
      else
        response_attributes  # If no version, keep the attributes unchanged.
      end

    # Step 8: Similarly, add the message content code to the response attributes if it's provided.
    response_attributes =
      if message_content_code != nil and message_content_code != "" do
        Map.put(response_attributes, "MessageContentCode", message_content_code)  # Add message content code if present.
      else
        response_attributes  # No changes if message content code is absent.
      end

    # Step 9: Create the full element name for the OTA response, prefixing it with the "ota:" namespace.
    # This ensures the response complies with the OTA standard.
    with_namespace_ota_response_name = "ota:" <> ota_response_name

    # Step 10: Determine the content of the SOAP body based on the presence of errors.
    # If there are errors, include them; otherwise, include the success element.
    body_elements = cond do
      # If errors are present, include an "ota:Errors" element containing the error details.
      error_elements != [] ->
        elements = [
          XmlBuilder.element("ota:Errors", error_elements)  # Add error elements if they exist.
        ]

        # The final body includes the OTA response name and error-related elements.
        [
          XmlBuilder.element(with_namespace_ota_response_name, response_attributes, elements)
        ]

      # If no errors, include the success element in the response.
      true ->
        [
          XmlBuilder.element(
            with_namespace_ota_response_name,
            response_attributes,
            [
              success_element  # Add success element to indicate a successful response.
            ]
          )
        ]
    end

    # Step 11: Build the complete SOAP envelope with both the header and body.
    # The envelope includes required namespaces for SOAP, OTA, and WSA (Web Services Addressing).
    XmlBuilder.document([
      XmlBuilder.element(
        "soap:Envelope",  # Root element for the SOAP envelope.
        %{
          "xmlns:soap" => "http://www.w3.org/2003/05/soap-envelope",  # SOAP namespace.
          "xmlns:ota" => "http://www.opentravel.org/OTA/2003/05",     # OTA namespace for travel standards.
          "xmlns:wsa" => "http://www.w3.org/2005/08/addressing"       # WSA namespace for web service addressing.
        },
        [
          header,  # SOAP header containing message addressing and metadata.
          XmlBuilder.element("soap:Body", body_elements)  # SOAP body containing response data (errors or success).
        ]
      )
    ])
    |> XmlBuilder.generate(format: :indented)  # Generate the final XML document with indentation for better readability.
  end

  # Private function to extract header values from the given message.
  # This retrieves fields such as UUID, message ID, recipient, action, and reply-to address from the message's header.
  defp extract_header_values(%{header: header}, uuid4) do
    %{
      uuid4: uuid4,  # Use the provided UUID (unique identifier for the message).
      message_id: get_in(header, [:message_id]),  # Extract the message ID from the header.
      to: get_in(header, [:to]),  # Extract the "To" field (message recipient).
      action: get_in(header, [:action]),  # Extract the action that the message corresponds to.
      address: get_in(header, [:reply_to, :address])  # Extract the reply-to address for responses.
    }
  end

  # Private function to build the SOAP header element.
  # This constructs the `<soap:Header>` with elements related to addressing, including the message ID, recipient, and reply-to information.
  defp build_header(uuid4, message_id, to, action, address) do
    XmlBuilder.element(
      "soap:Header",  # The root element for the SOAP header.
      [
        XmlBuilder.element("wsa:MessageID", uuid4),  # The unique message ID (UUID).
        XmlBuilder.element("wsa:RelatesTo", message_id),  # The message ID this response is related to.
        XmlBuilder.element("wsa:To", to),  # The recipient of the message.
        XmlBuilder.element("wsa:Action", action),  # The action being performed in the message.
        XmlBuilder.element("wsa:ReplyTo", [
          XmlBuilder.element("wsa:Address", address)  # The address where the response should be sent.
        ])
      ]
    )
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
