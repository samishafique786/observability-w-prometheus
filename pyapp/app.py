from flask import Flask, send_file, jsonify
from datetime import datetime
import pytz 

app = Flask(__name__)

@app.route("/gandalf")
def gandalf():
    return send_file("static/gandalf.jpg", mimetype="image/jpeg")

@app.route("/colombo")
def colombo():
    
    colombo_tz = pytz.timezone("Asia/Colombo")
    colombo_time = datetime.now(colombo_tz).strftime("%Y-%m-%d %H:%M:%S")

    return jsonify({"time_in_colombo": colombo_time})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
