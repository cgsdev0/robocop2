
source .secrets

HOST=${HTTP_HEADERS["Host"]}
PROTOCOL="https://"
if [[ "$HOST" =~ "localhost"* ]]; then
  PROTOCOL="http://"
fi

htmx_page << EOF
<div class="container">
  <h1>Robocop 2</h1>
  <p class="credit"><em>the sequel is always better, right?</em></p>
  <form hx-post="/register">
  <a class="twitch" href="/setup">Setup</a>
  </form>
</div>
EOF
