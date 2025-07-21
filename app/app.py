import time
import random
import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

# Global variable to control slow mode for testing alerts
# In a real app, this would be managed via config maps, feature flags, etc.
SLOW_MODE_ENABLED = False


@app.route("/health")
def health():
    return "The app is healthy", 200


@app.route("/checkout")
def checkout():
    try:
        # Simulate some internal logic for checkout
        # Introduce more varied base latency
        base_delay = random.uniform(0.05, 0.25)
        time.sleep(base_delay)

        # Introduce an intermittent spike in latency (e.g., 5% of the time)
        if random.random() < 0.05:
            spike_delay = random.uniform(0.5, 1.0)  # 500ms to 1000ms extra delay
            time.sleep(spike_delay)

        # If slow mode is enabled, add a consistent extra delay
        if SLOW_MODE_ENABLED:
            #time.sleep(random.uniform(0.3, 0.7))  # Add 300-700ms extra delay

            # Guarantee that P95 goes over 1.2s
            time.sleep(random.uniform(1.0, 1.5))  # Add 1000-1500ms extra delay

        # Call the "payment" microservice (hosted in same Flask app)
        url = "http://flask-app.flask-app-ns.svc.cluster.local:5000/payment"

        # Make the request to the payment service
        # Timeout is crucial here to prevent /checkout from hanging indefinitely
        resp = requests.get(url, timeout=2)

        # IMPORTANT: Check the status code from the payment service
        if resp.status_code != 200:
            # If payment service returned an error (e.g., 500),
            # propagate that error status or a derived error status for /checkout
            payment_error_data = resp.json()
            return jsonify({
                "message": "Checkout failed due to payment error",
                "payment_status": payment_error_data
            }), 500  # Return 500 if payment failed

        # If payment was successful
        return jsonify({
            "message": "Checkout successful",
            "payment_status": resp.json()
        }), 200

    except requests.exceptions.Timeout:
        # Handle specific timeout from the requests.get call
        return jsonify({"error": "External Payment Service Timeout"}), 504  # Gateway Timeout

    except requests.exceptions.ConnectionError:
        # Handle connection errors (e.g., payment service is down)
        return jsonify({"error": "Could not connect to Payment Service"}), 503  # Service Unavailable

    except Exception as e:
        # Catch any other unexpected errors during checkout
        return jsonify({"error": str(e)}), 500


@app.route("/payment")
def payment():
    # Simulate latency or failure
    # Introduce a controlled error rate (e.g., 25% chance of failure)
    # And varied successful delays
    if random.random() < 0.25:  # 25% chance of failure
        delay = random.uniform(1.0, 1.8)  # Simulate a longer delay before failure
        time.sleep(delay)
        return jsonify({"error": "Payment API timeout"}), 500
    else:
        delay = random.uniform(0.05, 0.3)  # Faster successful payments
        time.sleep(delay)
        return jsonify({"status": "payment processed"}), 200


# New endpoint to toggle slow mode for /checkout
# Exists form the charts 0.16.0 version
@app.route("/toggle-slow-mode", methods=["POST"])
def toggle_slow_mode():
    global SLOW_MODE_ENABLED
    SLOW_MODE_ENABLED = not SLOW_MODE_ENABLED
    status = "enabled" if SLOW_MODE_ENABLED else "disabled"
    return jsonify({"message": f"Slow mode for /checkout is now {status}"}), 200


# Flask will automatically use the value from the FLASK_RUN_PORT env var,
# or default to 5000 if it's not set
if __name__ == "__main__":
    app.run(host="0.0.0.0")
