from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def home():
    return jsonify({
        "message": "Production Flask CI/CD Demo"
    })


@app.route("/health")
def health():
    return jsonify({
        "status": "healthy"
    }), 200


@app.route("/version")
def version():
    return jsonify({
        "version": "local"
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
