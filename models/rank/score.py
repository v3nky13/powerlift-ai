import os
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

import pickle
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import tensorflow as tf
from tensorflow import keras

if not os.path.exists("op_data_clean.csv"):
    df = pd.read_csv("op_data.csv", usecols=['Name', 'Sex', 'Event', 'Equipment', 'Age', 'BodyweightKg',
                                            'Best3SquatKg', 'Best3BenchKg', 'Best3DeadliftKg', 'Date'])

    df.dropna(axis=0, how='any', inplace=True)

    df['Date'] = pd.to_datetime(df['Date'])

    df = df[df['Sex'].isin(['M', 'F']) & (df['Event'] == 'SBD')
            & (df['Best3SquatKg'] > 0) & (df['Best3BenchKg'] > 0) & (df['Best3DeadliftKg'] > 0)
            & (df['Date'].dt.year >= 1996)]

    df['Sex'] = df['Sex'].replace({'M': 1, 'F': 0})
    df['Equipment'] = df['Equipment'].replace({'Wraps': 1, 'Multi-ply': 1, 'Single-ply': 1,
                                            'Unlimited': 1, 'Straps': 1, 'Raw': 0})
    
    df = df.sort_values(by=['Name', 'Date']).reset_index(drop=True)
    
    result = []

    for name, group in df.groupby('Name'):
        records = group.to_dict('records')

        for i in range(len(records)):
            for j in range(i + 1, len(records)):
                current = records[i]
                future = records[j]
                diff_days = (future['Date'] - current['Date']).days
                result.append({
                    'Sex': current['Sex'],
                    'CurrentEquipment': current['Equipment'],
                    'CurrentAge': current['Age'],
                    'CurrentBodyweightKg': current['BodyweightKg'],
                    'CurrentBest3SquatKg': current['Best3SquatKg'],
                    'CurrentBest3BenchKg': current['Best3BenchKg'],
                    'CurrentBest3DeadliftKg': current['Best3DeadliftKg'],
                    'DiffDays': diff_days,
                    'FutureEquipment': future['Equipment'],
                    'FutureAge': future['Age'],
                    'FutureBodyweightKg': future['BodyweightKg'],
                    'FutureBest3SquatKg': future['Best3SquatKg'],
                    'FutureBest3BenchKg': future['Best3BenchKg'],
                    'FutureBest3DeadliftKg': future['Best3DeadliftKg'],
                })

    df = pd.DataFrame(result)

    df.to_csv("op_data_clean.csv", index=False)

# gpus = tf.config.list_physical_devices('GPU')

# if gpus:
#     print("GPUs available:")
#     for gpu in gpus:
#         print(gpu)
# else:
#     print("No GPUs available.")

df = pd.read_csv("op_data_clean.csv")

# plt.title('BodyweightKg vs. Best3SquatKg')
# plt.scatter(df['BodyweightKg'][:100000], df['Best3SquatKg'][:100000], s=1)
# plt.show()

X = df[['Sex', 'CurrentEquipment', 'CurrentAge', 'CurrentBodyweightKg',
        'CurrentBest3SquatKg', 'CurrentBest3BenchKg', 'CurrentBest3DeadliftKg',
        'DiffDays', 'FutureEquipment', 'FutureAge', 'FutureBodyweightKg']]
y = df[['FutureBest3SquatKg', 'FutureBest3BenchKg', 'FutureBest3DeadliftKg']]

# Normalize the feature data
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

if not os.path.exists("score_scaler.pkl"):
    with open("score_scaler.pkl", "wb") as f:
        pickle.dump(scaler, f)

X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.2, random_state=42)

if not os.path.exists("score_model.h5"):
    model = keras.Sequential([
        keras.layers.Dense(64, activation='relu', input_shape=(X_train.shape[1],)),  # Input layer
        keras.layers.Dense(32, activation='relu'),  # Hidden layer
        keras.layers.Dense(3)  # Output layer for squat, bench, deadlift
    ])

    model.compile(optimizer='adam', loss='mean_squared_error')

    history = model.fit(X_train, y_train, epochs=10, batch_size=32, validation_split=0.2)

    model.save('score_model.h5')

model = keras.models.load_model('score_model.h5')

# Evaluate the model
loss = model.evaluate(X_test, y_test)
print(f'Test Loss: {loss}')