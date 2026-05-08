#!/bin/bash

AVAIL_URL="${AVAIL_URL:-http://localhost:4000/soap/availability}"
HOTEL_CODE_BASE="${HOTEL_CODE_BASE:-38092}"
HOTEL_CODE_INTERVAL="${HOTEL_CODE_INTERVAL:-100}"
PARALLEL_JOBS="${PARALLEL_JOBS:-60}"
REQUEST_COUNT="${REQUEST_COUNT:-2000}"

if ! [[ "$HOTEL_CODE_BASE" =~ ^[0-9]+$ ]]; then
  echo "HOTEL_CODE_BASE must be a non-negative integer, got: $HOTEL_CODE_BASE" >&2
  exit 1
fi

if ! [[ "$HOTEL_CODE_INTERVAL" =~ ^[1-9][0-9]*$ ]]; then
  echo "HOTEL_CODE_INTERVAL must be a positive integer, got: $HOTEL_CODE_INTERVAL" >&2
  exit 1
fi

if ! [[ "$PARALLEL_JOBS" =~ ^[1-9][0-9]*$ ]]; then
  echo "PARALLEL_JOBS must be a positive integer, got: $PARALLEL_JOBS" >&2
  exit 1
fi

if ! [[ "$REQUEST_COUNT" =~ ^[1-9][0-9]*$ ]]; then
  echo "REQUEST_COUNT must be a positive integer, got: $REQUEST_COUNT" >&2
  exit 1
fi

run_avail_request() {
  local index=$1
  local hotel_code_offset=$(( (index - 1) / HOTEL_CODE_INTERVAL ))
  local hotel_code=$(( HOTEL_CODE_BASE + hotel_code_offset ))

  # shellcheck disable=SC2155
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%NZ")

  curl --location --request POST "$AVAIL_URL" \
    --header 'Content-Type: text/xml; charset=utf-8' \
    --header 'SOAPAction: Recipient' \
    --data-raw "<Envelope xmlns=\"http://www.w3.org/2003/05/soap-envelope\">
                    <soap2:Header xmlns:htng=\"http://htng.org/1.3/Header/\" xmlns:wsa=\"http://www.w3.org/2005/08/addressing\" xmlns:wss=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\" xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:htnga=\"http://htng.org/PWSWG/2007/02/AsyncHeaders\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:soap2=\"http://www.w3.org/2003/05/soap-envelope\">
                        <wsa:Action>OTA_HotelAvailNotifRQ</wsa:Action>
                        <wsa:ReplyTo>
                            <wsa:Address>http://www.w3.org/2005/08/addressing/role/anonymous</wsa:Address>
                        </wsa:ReplyTo>
                        <wss:Security mustUnderstand=\"1\">
                            <wss:UsernameToken>
                                <wss:Username>test@test.com</wss:Username>
                                <wss:Password>testpassword</wss:Password>
                            </wss:UsernameToken>
                        </wss:Security>
                        <wsa:MessageID>ed74600e-5925-441d-8565-ceefb00f3678$index</wsa:MessageID>
                        <wsa:To>https://aripush.xres.de/?ari=public</wsa:To>
                    </soap2:Header>
                    <Body>
                        <OTA_HotelAvailNotifRQ xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://www.opentravel.org/OTA/2003/05\" TimeStamp=\"$timestamp\" Version=\"3.000\" MessageContentCode=\"3\">
                            <AvailStatusMessages HotelCode=\"$hotel_code\">
                                <AvailStatusMessage>
                                    <StatusApplicationControl Start=\"2026-05-11\" End=\"2026-05-13\" RatePlanCode=\"PEPKN\" InvTypeCode=\"LXFUJD\" Mon=\"true\" Tue=\"true\" Weds=\"true\" Thur=\"false\" Fri=\"false\" Sat=\"false\" Sun=\"false\">
                                        <DestinationSystemCodes>
                                            <DestinationSystemCode>5935</DestinationSystemCode>
                                        </DestinationSystemCodes>
                                    </StatusApplicationControl>
                                    <UniqueID Type=\"16\" ID=\"1\"/>
                                    <RestrictionStatus Restriction=\"Master\" Status=\"Open\"/>
                                </AvailStatusMessage>
                                <AvailStatusMessage>
                                    <StatusApplicationControl Start=\"2026-05-11\" End=\"2026-05-13\" RatePlanCode=\"PEPKN\" InvTypeCode=\"LXFUJD\" Mon=\"true\" Tue=\"true\" Weds=\"true\" Thur=\"false\" Fri=\"false\" Sat=\"false\" Sun=\"false\">
                                        <DestinationSystemCodes>
                                            <DestinationSystemCode>5935</DestinationSystemCode>
                                        </DestinationSystemCodes>
                                    </StatusApplicationControl>
                                    <UniqueID Type=\"16\" ID=\"2\"/>
                                    <RestrictionStatus Restriction=\"Arrival\" Status=\"Open\"/>
                                </AvailStatusMessage>
                                <AvailStatusMessage>
                                    <StatusApplicationControl Start=\"2026-05-11\" End=\"2026-05-13\" RatePlanCode=\"PEPKN\" InvTypeCode=\"LXFUJD\" Mon=\"true\" Tue=\"true\" Weds=\"true\" Thur=\"false\" Fri=\"false\" Sat=\"false\" Sun=\"false\">
                                        <DestinationSystemCodes>
                                            <DestinationSystemCode>5935</DestinationSystemCode>
                                        </DestinationSystemCodes>
                                    </StatusApplicationControl>
                                    <UniqueID Type=\"16\" ID=\"3\"/>
                                    <RestrictionStatus Restriction=\"Departure\" Status=\"Open\"/>
                                </AvailStatusMessage>
                                <AvailStatusMessage>
                                    <StatusApplicationControl Start=\"2026-05-11\" End=\"2026-05-13\" RatePlanCode=\"PEPKN\" InvTypeCode=\"LXFUJD\" Mon=\"true\" Tue=\"true\" Weds=\"true\" Thur=\"false\" Fri=\"false\" Sat=\"false\" Sun=\"false\">
                                        <DestinationSystemCodes>
                                            <DestinationSystemCode>5935</DestinationSystemCode>
                                        </DestinationSystemCodes>
                                    </StatusApplicationControl>
                                    <LengthsOfStay>
                                        <LengthOfStay Time=\"1\" TimeUnit=\"Day\" MinMaxMessageType=\"SetForwardMinStay\"/>
                                        <LengthOfStay Time=\"0\" TimeUnit=\"Day\" MinMaxMessageType=\"SetForwardMaxStay\"/>
                                    </LengthsOfStay>
                                    <UniqueID Type=\"16\" ID=\"4\"/>
                                </AvailStatusMessage>
                                <AvailStatusMessage>
                                    <StatusApplicationControl Start=\"2026-05-11\" End=\"2026-05-13\" RatePlanCode=\"PEPKN\" InvTypeCode=\"LXFUJD\" Mon=\"true\" Tue=\"true\" Weds=\"true\" Thur=\"false\" Fri=\"false\" Sat=\"false\" Sun=\"false\">
                                        <DestinationSystemCodes>
                                            <DestinationSystemCode>5935</DestinationSystemCode>
                                        </DestinationSystemCodes>
                                    </StatusApplicationControl>
                                    <LengthsOfStay>
                                        <LengthOfStay Time=\"1\" TimeUnit=\"Day\" MinMaxMessageType=\"SetMinLOS\"/>
                                        <LengthOfStay Time=\"0\" TimeUnit=\"Day\" MinMaxMessageType=\"SetMaxLOS\"/>
                                    </LengthsOfStay>
                                    <UniqueID Type=\"16\" ID=\"5\"/>
                                </AvailStatusMessage>
                            </AvailStatusMessages>
                        </OTA_HotelAvailNotifRQ>
                    </Body>
                </Envelope>"
}

export -f run_avail_request
export AVAIL_URL HOTEL_CODE_BASE HOTEL_CODE_INTERVAL PARALLEL_JOBS REQUEST_COUNT

time parallel -j "$PARALLEL_JOBS" run_avail_request ::: $(seq 1 "$REQUEST_COUNT")
