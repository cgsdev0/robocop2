# headers

source .secrets

SIGNATURE=${HTTP_HEADERS['Twitch-Eventsub-Message-Signature']}
TOPIC=${HTTP_HEADERS['Twitch-Eventsub-Subscription-Type']}
MSG_ID=${HTTP_HEADERS['Twitch-Eventsub-Message-Id']}
TIMESTAMP=${HTTP_HEADERS['Twitch-Eventsub-Message-Timestamp']}
TYPE=${HTTP_HEADERS['Twitch-Eventsub-Message-Type']}
HMAC_MSG="${MSG_ID}${TIMESTAMP}${REQUEST_BODY}"

SIGNATURE2="sha256=$(echo -n "$HMAC_MSG" | openssl sha256 -hmac "$TWITCH_EVENTSUB_SECRET" | cut -d' ' -f2)"

if [[ -z "$SIGNATURE" ]] || [[ -z "$SIGNATURE2" ]] || [[ "$SIGNATURE" != "$SIGNATURE2" ]]; then
  echo "invalid signature"
  return $(status_code 400)
fi

if [[ "$TYPE" == "webhook_callback_verification" ]]; then
  CHALLENGE=$(echo "$REQUEST_BODY" | jq -r '.challenge')
  CHALLEN=$(echo "$CHALLENGE" | wc -c)
  printf "%s\r\n" "Content-Type: $CHALLEN"
  printf "\r\n"
  printf "\r\n"
  echo "$CHALLENGE"
  return $(status_code 200)
fi

printf "\r\n"
printf "\r\n"

if [[ "$TYPE" == "notification" ]]; then
  USER_ID=$(echo "$REQUEST_BODY" | jq -r '.event.broadcaster_user_id')
  if [[ "$USER_ID" == "56931496" ]]; then
    curl -Ss -x POST "$DISCORD_WEBHOOK" \
      -H "Content-Type: application/json" \
      -d '{"content": badcop just went live! Come hang out at https://twitch.tv/badcop_"}' 1>&2
  fi
  return $(status_code 204)
fi
