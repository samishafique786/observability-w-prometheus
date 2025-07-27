from flask import Flask, send_file

app = Flask(__name__)

@app.route("/gandalf")
def gandalf():
    return send_file("static/gandalf.jpg", mimetype="image/jpeg")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
