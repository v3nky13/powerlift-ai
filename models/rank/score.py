import os
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

import pandas as pd
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import tensorflow as tf
from tensorflow import keras

# df = pd.read_csv("op_data.csv", usecols=['Sex', 'Event', 'Equipment', 'Age', 'BodyweightKg',
#                                          'Best3SquatKg', 'Best3BenchKg', 'Best3DeadliftKg', 'Date'])

# df.dropna(axis=0, how='any', inplace=True)

# df['Date'] = pd.to_datetime(df['Date'])

# df = df[df['Sex'].isin(['M', 'F']) & (df['Event'] == 'SBD')
#         & (df['Best3SquatKg'] > 0) & (df['Best3BenchKg'] > 0) & (df['Best3DeadliftKg'] > 0)
#         & (df['Date'].dt.year >= 1996)]

# df['Sex'] = df['Sex'].replace({'M': 1, 'F': 0})
# df['Equipment'] = df['Equipment'].replace({'Wraps': 1, 'Multi-ply': 1, 'Single-ply': 1,
#                                            'Unlimited': 1, 'Straps': 1, 'Raw': 0})

# df.drop(['Event', 'Date'], axis=1, inplace=True)

# df.reset_index(drop=True, inplace=True)

# df.to_csv("op_data_clean.csv", index=False)

# df = pd.read_csv("op_data_clean.csv")

# plt.title('BodyweightKg vs. Best3SquatKg')
# plt.scatter(df['BodyweightKg'][:100000], df['Best3SquatKg'][:100000], s=1)
# plt.show()

gpus = tf.config.list_physical_devices('GPU')

if gpus:
    print("GPUs available:")
    for gpu in gpus:
        print(gpu)
else:
    print("No GPUs available.")

# Load the cleaned data
df = pd.read_csv("op_data_clean.csv")

# Define input features and target outputs
X = df[['BodyweightKg', 'Age', 'Sex', 'Equipment']]
y = df[['Best3SquatKg', 'Best3BenchKg', 'Best3DeadliftKg']]

# Normalize the feature data
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Split the data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.2, random_state=42)

# # Define the ANN model
# model = keras.Sequential([
#     keras.layers.Dense(64, activation='relu', input_shape=(X_train.shape[1],)),  # Input layer
#     keras.layers.Dense(32, activation='relu'),  # Hidden layer
#     keras.layers.Dense(3)  # Output layer for squat, bench, deadlift
# ])

# # Compile the model
# model.compile(optimizer='adam', loss='mean_squared_error')

# # Train the model
# history = model.fit(X_train, y_train, epochs=100, batch_size=32, validation_split=0.2)

# model.save('score_model.h5')

model = keras.models.load_model('score_model.h5')

# Evaluate the model
# loss = model.evaluate(X_test, y_test)
# print(f'Test Loss: {loss}')

# Make predictions
predictions = model.predict(X_test)

# print actual and predicted values
for i in range(10):
    print(f'[{i}]\nActual:\n{y_test.iloc[i]}\n\nPredicted:\n{predictions[i]}\n')