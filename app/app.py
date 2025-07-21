import time
import random
from flask import Flask, jsonify

app = Flask(__name__)

# --- Configuration for Automatic Peaks ---
# Time when the next peak period should start
next_peak_start_time = time.time() + random.choice([60, 120, 180]) # Initial peak in 1, 2, or 3 minutes
peak_duration_seconds = 30 # How long the peak effect lasts (e.g., 30 seconds)

# Latency ranges
NORMAL_LATENCY_MS_MIN = 50
NORMAL_LATENCY_MS_MAX = 150
PEAK_LATENCY_MS_MIN = 1800 # 1.8 seconds
PEAK_LATENCY_MS_MAX = 2500 # 2.5 seconds

# Error rates (as a percentage chance)
NORMAL_ERROR_RATE_PERCENT = 5  # 5% chance of error in normal mode
PEAK_ERROR_RATE_PERCENT = 70   # 70% chance of error in peak mode
# --- End Configuration ---

@app.route("/health")
def health():
    """Simple health check endpoint."""
    return "The app is healthy", 200

@app.route("/checkout")
def checkout():
    global next_peak_start_time # Declare global to modify the timestamp

    current_time = time.time()
    is_in_peak_period = False

    # Check if it's time for a peak
    if current_time >= next_peak_start_time:
        # If we are past the peak start time, check if we are still within the peak duration
        if current_time < (next_peak_start_time + peak_duration_seconds):
            is_in_peak_period = True
        else:
            # The current peak period has ended, schedule the next one
            # Choose a random interval (1, 2, or 3 minutes) for the *next* peak
            random_interval_seconds = random.choice([60, 120, 180])
            next_peak_start_time = current_time + random_interval_seconds
            print(f"Peak period ended. Next peak scheduled for {random_interval_seconds} seconds from now ({time.ctime(next_peak_start_time)})")


    # Apply behavior based on whether we are in a peak period
    if is_in_peak_period:
        # Latency for peak
        delay_ms = random.uniform(PEAK_LATENCY_MS_MIN, PEAK_LATENCY_MS_MAX)
        # Error rate for peak
        should_error = random.random() * 100 < PEAK_ERROR_RATE_PERCENT
        mode = "PEAK"
    else:
        # Latency for normal
        delay_ms = random.uniform(NORMAL_LATENCY_MS_MIN, NORMAL_LATENCY_MS_MAX)
        # Error rate for normal
        should_error = random.random() * 100 < NORMAL_ERROR_RATE_PERCENT
        mode = "NORMAL"

    time.sleep(delay_ms / 1000.0) # Convert milliseconds to seconds for time.sleep

    if should_error:
        print(f"[{mode} MODE] Checkout FAILED (Simulated Error) after {delay_ms:.2f}ms")
        return jsonify({"message": f"Checkout failed in {mode} mode (simulated error)"}), 500
    else:
        print(f"[{mode} MODE] Checkout SUCCESS after {delay_ms:.2f}ms")
        return jsonify({"message": f"Checkout successful in {mode} mode"}), 200


if __name__ == "__main__":
    # The Flask development server
    print(f"Application starting. Initial peak scheduled for {time.ctime(next_peak_start_time)}")
    app.run(host="0.0.0.0", port=5000)