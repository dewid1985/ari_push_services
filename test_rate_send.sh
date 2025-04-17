#!/bin/bash

run_myscript() {
  local index=$1

  # shellcheck disable=SC2155
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%NZ")

  curl --location --request POST 'http://localhost:4000/soap/rate' \
    --header 'Content-Type: text/xml; charset=utf-8' \
    --header 'SOAPAction: Recipient' \
    --data-raw "<Envelope xmlns=\"http://www.w3.org/2003/05/soap-envelope\">
                    <soap2:Header xmlns:htng=\"http://htng.org/1.3/Header/\" xmlns:wsa=\"http://www.w3.org/2005/08/addressing\" xmlns:wss=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\" xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:htnga=\"http://htng.org/PWSWG/2007/02/AsyncHeaders\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:soap2=\"http://www.w3.org/2003/05/soap-envelope\">
                        <wsa:Action>OTA_HotelRatePlanNotifRQ</wsa:Action>
                        <wsa:ReplyTo>
                            <wsa:Address>http://www.w3.org/2005/08/addressing/role/anonymous</wsa:Address>
                        </wsa:ReplyTo>
                        <wss:Security mustUnderstand=\"1\">
                            <wss:UsernameToken>
                                <wss:Username>test@test.com</wss:Username>
                                <wss:Password>testpassword</wss:Password>
                            </wss:UsernameToken>
                        </wss:Security>
                        <wsa:MessageID>38addccd-2a5f-4512-8158-858b9f2a96c7$index</wsa:MessageID>
                        <wsa:To>https://aripush.xres.de/?ari=public</wsa:To>
                    </soap2:Header>
                    <Body>
                        <OTA_HotelRatePlanNotifRQ xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://www.opentravel.org/OTA/2003/05\" TimeStamp=\"$timestamp\" Version=\"$index\" MessageContentCode=\"8\">
                            <RatePlans HotelCode=\"36572\" ID=\"$index\" >
                                <RatePlan Start=\"2025-08-22\" End=\"2025-08-27\" RatePlanCode=\"IA_EXP1_PEX\" RatePlanNotifType=\"Delta\">
                                    <DestinationSystemsCode>
                                        <DestinationSystemCode>6105</DestinationSystemCode>
                                    </DestinationSystemsCode>
                                    <Rates>
                                        <Rate Mon=\"true\" Tue=\"true\" Weds=\"true\" Thur=\"true\" Fri=\"false\" Sat=\"true\" Sun=\"true\" CurrencyCode=\"EUR\" InvTypeCode=\"STD_GCV\">
                                            <BaseByGuestAmts>
                                                <BaseByGuestAmt AmountBeforeTax=\"244\" AmountAfterTax=\"244\" NumberOfGuests=\"1\" AgeQualifyingCode=\"10\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"244\" AmountAfterTax=\"244\" NumberOfGuests=\"2\" AgeQualifyingCode=\"10\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"0\" MaxAge=\"1\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"30.5\" AmountAfterTax=\"30.5\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"2\" MaxAge=\"5\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"42.7\" AmountAfterTax=\"42.7\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"6\" MaxAge=\"14\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"73.2\" AmountAfterTax=\"73.2\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"15\" MaxAge=\"17\"/>
                                            </BaseByGuestAmts>
                                        </Rate>
                                    </Rates>
                                    <UniqueID Type=\"16\" ID=\"1\"/>
                                </RatePlan>
                                <RatePlan Start=\"2025-08-25\" End=\"2025-08-25\" RatePlanCode=\"IA_EXP1_PEX\" RatePlanNotifType=\"Delta\">
                                    <DestinationSystemsCode>
                                        <DestinationSystemCode>6105</DestinationSystemCode>
                                    </DestinationSystemsCode>
                                    <Rates>
                                        <Rate Mon=\"true\" Tue=\"false\" Weds=\"false\" Thur=\"false\" Fri=\"false\" Sat=\"false\" Sun=\"false\" CurrencyCode=\"EUR\" InvTypeCode=\"STD_GCV\">
                                            <BaseByGuestAmts>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"10\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"2\" AgeQualifyingCode=\"10\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"0\" MaxAge=\"1\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"2\" MaxAge=\"5\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"6\" MaxAge=\"14\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"15\" MaxAge=\"17\"/>
                                            </BaseByGuestAmts>
                                        </Rate>
                                    </Rates>
                                    <UniqueID Type=\"16\" ID=\"7\"/>
                                </RatePlan>
                                <RatePlan Start=\"2025-08-30\" End=\"2025-08-30\" RatePlanCode=\"IA_EXP1_PEX\" RatePlanNotifType=\"Delta\">
                                    <DestinationSystemsCode>
                                        <DestinationSystemCode>6105</DestinationSystemCode>
                                    </DestinationSystemsCode>
                                    <Rates>
                                        <Rate Mon=\"false\" Tue=\"false\" Weds=\"false\" Thur=\"false\" Fri=\"false\" Sat=\"true\" Sun=\"false\" CurrencyCode=\"EUR\" InvTypeCode=\"STD_GCV\">
                                            <BaseByGuestAmts>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"10\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"2\" AgeQualifyingCode=\"10\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"0\" MaxAge=\"1\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"2\" MaxAge=\"5\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"6\" MaxAge=\"14\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"15\" MaxAge=\"17\"/>
                                            </BaseByGuestAmts>
                                        </Rate>
                                    </Rates>
                                    <UniqueID Type=\"16\" ID=\"8\"/>
                                </RatePlan>
                                <RatePlan Start=\"2025-09-06\" End=\"2025-09-13\" RatePlanCode=\"IA_EXP1_PEX\" RatePlanNotifType=\"Delta\">
                                    <DestinationSystemsCode>
                                        <DestinationSystemCode>6105</DestinationSystemCode>
                                    </DestinationSystemsCode>
                                    <Rates>
                                        <Rate Mon=\"true\" Tue=\"true\" Weds=\"true\" Thur=\"true\" Fri=\"true\" Sat=\"true\" Sun=\"true\" CurrencyCode=\"EUR\" InvTypeCode=\"STD_GCV\">
                                            <BaseByGuestAmts>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"10\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"2\" AgeQualifyingCode=\"10\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"0\" MaxAge=\"1\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"2\" MaxAge=\"5\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"6\" MaxAge=\"14\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"15\" MaxAge=\"17\"/>
                                            </BaseByGuestAmts>
                                        </Rate>
                                    </Rates>
                                    <UniqueID Type=\"16\" ID=\"9\"/>
                                </RatePlan>
                                <RatePlan Start=\"2025-09-28\" End=\"2025-09-30\" RatePlanCode=\"IA_EXP1_PEX\" RatePlanNotifType=\"Delta\">
                                    <DestinationSystemsCode>
                                        <DestinationSystemCode>6105</DestinationSystemCode>
                                    </DestinationSystemsCode>
                                    <Rates>
                                        <Rate Mon=\"true\" Tue=\"true\" Weds=\"false\" Thur=\"false\" Fri=\"false\" Sat=\"false\" Sun=\"true\" CurrencyCode=\"EUR\" InvTypeCode=\"STD_GCV\">
                                            <BaseByGuestAmts>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"10\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"2\" AgeQualifyingCode=\"10\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"0\" MaxAge=\"1\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"2\" MaxAge=\"5\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"6\" MaxAge=\"14\"/>
                                                <BaseByGuestAmt AmountBeforeTax=\"0\" AmountAfterTax=\"0\" NumberOfGuests=\"1\" AgeQualifyingCode=\"8\" MinAge=\"15\" MaxAge=\"17\"/>
                                            </BaseByGuestAmts>
                                        </Rate>
                                    </Rates>
                                    <UniqueID Type=\"16\" ID=\"17\"/>
                                </RatePlan>
                            </RatePlans>
                        </OTA_HotelRatePlanNotifRQ>
                    </Body>
                </Envelope>"
}

export -f run_myscript

time parallel -j 60 run_myscript ::: {1..2000}