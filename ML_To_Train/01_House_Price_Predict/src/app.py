import os
from flask import Flask, request, jsonify
from flask_cors import CORS

from processing.preprocessing import preprocess_prompt
from output.predictor import predict_price

app = Flask(__name__)
CORS(app)  

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")


@app.route("/", methods=["GET"])
def home():
    return jsonify({"message": "House Price Prediction API is running"})


@app.route("/predict", methods=["POST"])
def predict():
    try:
        body = request.get_json()

        if not body or "prompt" not in body:
            return jsonify({"error": "Missing 'prompt' in request body"}), 400

        prompt = body["prompt"]

        if not GEMINI_API_KEY:
            return jsonify({"error": "GEMINI_API_KEY not set in environment"}), 500

        features_np = preprocess_prompt(prompt, GEMINI_API_KEY)
        predicted_price = int(predict_price(features_np))

        return jsonify({
            "predicted_sale_price": predicted_price
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True)
