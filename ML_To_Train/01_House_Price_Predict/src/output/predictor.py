import os
import pickle
import numpy as np


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS_DIR = os.path.join(BASE_DIR, "..", "models")

# Loadss model
with open(os.path.join(MODELS_DIR, "lasso_model.pkl"), "rb") as f:
    lasso_model = pickle.load(f)

with open(os.path.join(MODELS_DIR, "lr_model.pkl"), "rb") as f:
    lr_model = pickle.load(f)

with open(os.path.join(MODELS_DIR, "ridge_model.pkl"), "rb") as f:
    ridge_model = pickle.load(f)


def predict_price(features_np: np.ndarray) -> float:
    """
    features_np must be shape (1, n_features)
    """

    pred_lr = lr_model.predict(features_np)
    predict_lasso = lasso_model.predict(features_np)
    predict_ridge = ridge_model.predict(features_np)

    avg_pred = (pred_lr[0] + predict_lasso[0] + predict_ridge[0]) / 3

    return float(avg_pred)
