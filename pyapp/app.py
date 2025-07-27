from flask import Flask, send_file, jsonify
from datetime import datetime
import pytz
from prometheus_client import Counter, generate_latest

app = Flask(__name__)

requests_gandalf = Counter('requests_gandalf_total', 'Total requests to /gandalf')
requests_colombo = Counter('requests_colombo_total', 'Total requests to /colombo')

@app.route("/gandalf")
def gandalf():
    requests_gandalf.inc()
    return send_file("static/gandalf.jpg", mimetype="image/jpeg")

@app.route("/colombo")
def colombo():
    requests_colombo.inc()
    colombo_tz = pytz.timezone("Asia/Colombo")
    colombo_time = datetime.now(colombo_tz).strftime("%Y-%m-%d %H:%M:%S")
    return jsonify({"time_in_colombo": colombo_time})

@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {'Content-Type': 'text/plain; charset=utf-8'}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
