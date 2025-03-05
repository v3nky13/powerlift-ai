import pickle
from tensorflow import keras
import numpy as np

# Load the rank model and scaler
rank_scaler = pickle.load(open("rank_scaler.pkl", "rb"))
rank_model_params = pickle.load(open("rank_model.pkl", "rb"))

W = rank_model_params['W']
b = rank_model_params['b']
beta = rank_model_params['beta']

def rc_elm_predict(X, W, b, beta):
    H = np.tanh(np.dot(X, W.T) + b)
    return np.dot(H, beta)

# Example input data
input_data = np.array([
    [0, 1, 2, 75.0, 150.0, 100.0, 200.0]  # Example values
])

# Preprocess the input data
input_data_scaled = rank_scaler.transform(input_data)

# Make predictions
rank_pred = rc_elm_predict(input_data_scaled, W, b, beta)

# Print the results
print(f"Predicted rank score: {rank_pred[0][0]}")