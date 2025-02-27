import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_absolute_error, r2_score
from scipy.linalg import pinv

# Load dataset
df = pd.read_csv("222324.csv")

df['Sex'] = df['Sex'].replace({'M': 0, 'F': 1})
df['Equipment'] = df['Equipment'].replace({'C': 0, 'E': 1})
df['AgeCat'] = df['AgeCat'].replace({'SJ': 0, 'J': 1, 'O': 2})

df['BestSquat'] = pd.to_numeric(df['BestSquat'].apply(lambda x: x.split()[0]), errors='coerce')
df['BestBench'] = pd.to_numeric(df['BestBench'].apply(lambda x: x.split()[0]), errors='coerce')
df['BestDeadlift'] = pd.to_numeric(df['BestDeadlift'].apply(lambda x: x.split()[0]), errors='coerce')
df.dropna(inplace=True)

X = df[['Sex', 'Equipment', 'AgeCat', 'WtCat', 'BestSquat', 'BestBench', 'BestDeadlift']].astype(np.float32)
y = df[['Place']].astype(np.float32)

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# RC-ELM Implementation
def rc_elm_train(X, y, hidden_neurons, C):
    input_dim = X.shape[1]
    
    # Random weight initialization
    W = np.random.uniform(-1, 1, (hidden_neurons, input_dim))
    b = np.random.uniform(-1, 1, hidden_neurons)
    
    # Hidden layer output
    H = np.tanh(np.dot(X, W.T) + b)
    
    # Compute output weights with regularization
    beta = np.dot(pinv(np.dot(H.T, H) + C * np.identity(hidden_neurons)), np.dot(H.T, y))
    return W, b, beta

def rc_elm_predict(X, W, b, beta):
    H = np.tanh(np.dot(X, W.T) + b)
    return np.dot(H, beta)

# WOA for Hyperparameter Optimization
def woa_optimization(X_train, y_train, search_agents=10, iterations=20):
    lb, ub = 10, 200  # Hidden neurons search space
    best_hidden = None
    best_C = None
    best_score = float("inf")
    
    hidden_neurons = np.random.randint(lb, ub, search_agents)
    C_values = np.random.uniform(0.01, 10, search_agents)
    
    for _ in range(iterations):
        for i in range(search_agents):
            W, b, beta = rc_elm_train(X_train, y_train, hidden_neurons[i], C_values[i])
            y_pred = rc_elm_predict(X_train, W, b, beta)
            score = mean_absolute_error(y_train, y_pred)
            
            if score < best_score:
                best_score = score
                best_hidden = hidden_neurons[i]
                best_C = C_values[i]
    
    return best_hidden, best_C

# Find best hyperparameters using WOA
optimal_hidden, optimal_C = woa_optimization(X_train_scaled, y_train)

# Train final RC-ELM model
W, b, beta = rc_elm_train(X_train_scaled, y_train, optimal_hidden, optimal_C)

y_pred = rc_elm_predict(X_test_scaled, W, b, beta)

# Evaluation
mae = mean_absolute_error(y_test, y_pred)
r2 = r2_score(y_test, y_pred)

print(f"MAE: {mae:.4f}")
print(f"R² Score: {r2:.4f}")