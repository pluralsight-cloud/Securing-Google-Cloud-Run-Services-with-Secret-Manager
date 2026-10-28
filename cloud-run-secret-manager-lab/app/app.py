
import os
from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def home():
    token = os.environ.get("NOTIFY_TOKEN")

    if not token:
        return jsonify({
            "service": "order-notifier",
            "status": "error",
            "notification": "not configured"
        }), 500

    return jsonify({
        "service": "order-notifier",
        "status": "ok",
        "notification": "configured"
    })


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.environ.get("PORT", "8080"))
    )
