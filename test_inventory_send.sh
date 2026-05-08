#!/bin/bash

INVENTORY_URL="${INVENTORY_URL:-http://localhost:4000/soap/inventory}"
HOTEL_CODE_BASE="${HOTEL_CODE_BASE:-44188}"
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

run_inventory_request() {
  local index=$1
  local hotel_code_offset=$(( (index - 1) / HOTEL_CODE_INTERVAL ))
  local hotel_code=$(( HOTEL_CODE_BASE + hotel_code_offset ))

  # shellcheck disable=SC2155
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%NZ")

  curl --location --request POST "$INVENTORY_URL" \
    --header 'Content-Type: text/xml; charset=utf-8' \
    --header 'SOAPAction: Recipient' \
    --data-raw "<Envelope xmlns=\"http://www.w3.org/2003/05/soap-envelope\">
                    <soap2:Header xmlns:htng=\"http://htng.org/1.3/Header/\" xmlns:wsa=\"http://www.w3.org/2005/08/addressing\" xmlns:wss=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\" xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:htnga=\"http://htng.org/PWSWG/2007/02/AsyncHeaders\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:soap2=\"http://www.w3.org/2003/05/soap-envelope\">
                        <wsa:Action>OTA_HotelInvCountNotifRQ</wsa:Action>
                        <wsa:ReplyTo>
                            <wsa:Address>http://www.w3.org/2005/08/addressing/role/anonymous</wsa:Address>
                        </wsa:ReplyTo>
                        <wss:Security mustUnderstand=\"1\">
                            <wss:UsernameToken>
                                <wss:Username>test@test.com</wss:Username>
                                <wss:Password>testpassword</wss:Password>
                            </wss:UsernameToken>
                        </wss:Security>
                        <wsa:MessageID>84b489e1-3a47-4258-8d57-591c4811c7af$index</wsa:MessageID>
                        <wsa:To>https://aripush.xres.de/?ari=public</wsa:To>
                    </soap2:Header>
                    <Body>
                        <OTA_HotelInvCountNotifRQ xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://www.opentravel.org/OTA/2003/05\" TimeStamp=\"$timestamp\" Version=\"2.00\">
                            <UniqueID/>
                            <Inventories HotelCode=\"$hotel_code\">
                                <Inventory>
                                    <StatusApplicationControl Start=\"2026-05-15\" End=\"2026-05-15\" InvTypeCode=\"BVL\">
                                        <DestinationSystemCodes>
                                            <DestinationSystemCode>5935</DestinationSystemCode>
                                        </DestinationSystemCodes>
                                    </StatusApplicationControl>
                                    <InvCounts>
                                        <InvCount CountType=\"2\" Count=\"7\"/>
                                        <InvCount CountType=\"3\" Count=\"7\"/>
                                    </InvCounts>
                                </Inventory>
                                <Inventory>
                                    <StatusApplicationControl Start=\"2026-05-16\" End=\"2026-05-16\" InvTypeCode=\"BVL\">
                                        <DestinationSystemCodes>
                                            <DestinationSystemCode>5935</DestinationSystemCode>
                                        </DestinationSystemCodes>
                                    </StatusApplicationControl>
                                    <InvCounts>
                                        <InvCount CountType=\"2\" Count=\"14\"/>
                                        <InvCount CountType=\"3\" Count=\"14\"/>
                                    </InvCounts>
                                </Inventory>
                                <UniqueID Type=\"16\"/>
                            </Inventories>
                        </OTA_HotelInvCountNotifRQ>
                    </Body>
                </Envelope>"
}

export -f run_inventory_request
export INVENTORY_URL HOTEL_CODE_BASE HOTEL_CODE_INTERVAL PARALLEL_JOBS REQUEST_COUNT

time parallel -j "$PARALLEL_JOBS" run_inventory_request ::: $(seq 1 "$REQUEST_COUNT")
