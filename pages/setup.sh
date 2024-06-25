
source .secrets

HOST=${HTTP_HEADERS["Host"]}
PROTOCOL="https://"
if [[ "$HOST" =~ "localhost"* ]]; then
  PROTOCOL="http://"
fi

# get an app access token
TWITCH_RESPONSE=$(curl -Ss -X POST \
  "https://id.twitch.tv/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=${TWITCH_CLIENT_ID}&client_secret=${TWITCH_CLIENT_SECRET}&grant_type=client_credentials")

ACCESS_TOKEN=$(echo "$TWITCH_RESPONSE" | jq -r '.access_token')

# we have to get the stupid user id
TWITCH_RESPONSE=$(curl -Ss -X GET 'https://id.twitch.tv/oauth2/validate' \
  -H "Authorization: OAuth ${ACCESS_TOKEN}")

USER_ID=$(echo "$TWITCH_RESPONSE" | jq -r '.user_id')
RESPONSE="<pre>${TWITCH_RESPONSE}</pre>"

if [[ -z "$USER_ID" ]] || [[ "$USER_ID" == "null" ]]; then
  htmx_page << EOF
  <div class="container">
    <h1>Error</h1>
    ${RESPONSE}
    <p>Something went wrong registering for Redemption ARC. :(</p>
    <p><a href="/">Back to Home</a></p>
  </div>
EOF
  return $(status_code 400)
fi

if [[ "$USER_ID" != "56931496" ]] && [[ "$USER_ID" != "771248818" ]]; then
  htmx_page << EOF
  <div class="container">
    <h1>Error</h1>
    ${RESPONSE}
    <p>this app is not for you go away</p>
    <p><a href="/">Back to Home</a></p>
  </div>
EOF
  return $(status_code 400)
fi

# register the webhook using the access token
TWITCH_RESPONSE=$(curl -Ss -X POST 'https://api.twitch.tv/helix/eventsub/subscriptions' \
-H "Authorization: Bearer ${ACCESS_TOKEN}" \
-H "Client-Id: ${TWITCH_CLIENT_ID}" \
-H 'Content-Type: application/json' \
-d '{"type":"stream.online","version":"1","condition":{"broadcaster_user_id":"'"$USER_ID"'"},"transport":{"method":"webhook","callback":"https://robocop.bashsta.cc/webhook","secret":"'${TWITCH_EVENTSUB_SECRET}'"}}')

HAS_DATA=$(echo "$TWITCH_RESPONSE" | jq -r '.data')
STATUS=$(echo "$TWITCH_RESPONSE" | jq -r '.status')
RESPONSE="<pre>$TWITCH_RESPONSE</pre>"

if [[ "$HAS_DATA" == "null" ]]; then
  htmx_page << EOF
  <div class="container">
    <h1>Robocop 2</h1>
    ${RESPONSE}
    <p>Something went wrong setting up the EventSub subscription. :(</p>
    <p><a href="/">Back to Home</a></p>
  </div>
EOF
  return $(status_code 400)
fi

htmx_page << EOF
<div class="container">
  <h1>Robocop 2</h1>
  <p>Successfully registered webhooks.</p>
</div>
EOF
