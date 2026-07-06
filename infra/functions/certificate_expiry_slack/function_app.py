import datetime as dt
import json
import logging
import os
import urllib.request

import azure.functions as func

app = func.FunctionApp()


def format_expiry(expiry_timestamp):
    if not expiry_timestamp:
        return "알 수 없음"
    return dt.datetime.fromtimestamp(expiry_timestamp, tz=dt.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")


@app.function_name(name="certificateExpirySlackAlert")
@app.event_grid_trigger(arg_name="event")
def certificate_expiry_slack_alert(event: func.EventGridEvent):
    webhook_url = os.environ["SLACK_WEBHOOK_URL"]
    data = event.get_json()

    is_expired = event.event_type == "Microsoft.KeyVault.CertificateExpired"
    severity = ":rotating_light:" if is_expired else ":warning:"
    state = "만료됨" if is_expired else "만료 임박"
    message = {
        "text": (
            f"{severity} *TLS 인증서 {state}*\\n"
            f"• 인증서: `{data.get('ObjectName', '알 수 없음')}`\\n"
            f"• Key Vault: `{data.get('VaultName', '알 수 없음')}`\\n"
            f"• 만료 시각: {format_expiry(data.get('EXP'))}"
        )
    }

    request = urllib.request.Request(
        webhook_url,
        data=json.dumps(message).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            if response.status < 200 or response.status >= 300:
                raise RuntimeError(f"Slack webhook returned HTTP {response.status}")
    except Exception:
        logging.exception("Failed to deliver certificate expiry alert to Slack")
        raise
