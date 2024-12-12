import os
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

import pickle
from tensorflow import keras

scaler = pickle.load(open("score_scaler.pkl", "rb"))

model = keras.models.load_model('score_model.h5')

input_data = [
    [1, 0, 27.0, 80.0, 120.0, 80.0, 180.0, 93, 0, 27.0, 85.0]
]

input_scaled = scaler.transform(input_data)

print(model.predict(input_scaled))