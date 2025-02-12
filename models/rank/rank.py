import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
import keras

pd.set_option('future.no_silent_downcasting', True)

df = pd.read_csv("222324.csv")

df['Sex'] = df['Sex'].replace({'M': 0, 'F': 1})
df['Equipment'] = df['Equipment'].replace({'C': 0, 'E': 1})
df['AgeCat'] = df['AgeCat'].replace({'SJ': 0, 'J': 1, 'O': 2})

df['BestSquat'] = df['BestSquat'].apply(lambda x: x.split()[0])
df['BestBench'] = df['BestBench'].apply(lambda x: x.split()[0])
df['BestDeadlift'] = df['BestDeadlift'].apply(lambda x: x.split()[0])

df.to_csv("rank_data.csv", index=False)

X = df[['Sex', 'Equipment', 'AgeCat', 'WtCat', 'BestSquat', 'BestBench', 'BestDeadlift']].astype(np.float32)
y = df[['Place']].astype(np.float32)

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = keras.Sequential([
    keras.layers.Dense(32, activation='relu', input_shape=(X_train.shape[1],)),
    keras.layers.Dense(16, activation='relu'),
    keras.layers.Dense(1)
])

model.compile(optimizer='adam', loss='mean_squared_error', metrics=['mae'])

model.fit(X_train, y_train, epochs=20, batch_size=8, validation_split=0.2)

model.save('rank_model.h5')

model.evaluate(X_test, y_test)