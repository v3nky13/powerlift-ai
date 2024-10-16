import gymnasium as gym
import numpy as np
from stable_baselines3 import PPO

class PowerliftingEnv(gym.Env):
    def __init__(self):
        super(PowerliftingEnv, self).__init__()
        
        # Define action space: 
        # 0 - Decrease weight
        # 1 - Increase weight
        # 2 - Rest day
        self.action_space = gym.spaces.Discrete(3)

        # Observation space: athlete's state (e.g., fatigue, strength, soreness, etc.)
        # Example: [current_strength, fatigue_level, soreness, progress_rate, days_since_rest]
        self.observation_space = gym.spaces.Box(low=0, high=1, shape=(5,), dtype=np.float32)

        # Initial state (normalized between 0 and 1)
        self.state = np.random.rand(5)
        
        # Internal attributes to track athlete's stats
        self.current_strength = np.random.uniform(0.5, 1.0)  # normalized value between 0.5 to 1 (good initial strength)
        self.fatigue_level = np.random.uniform(0, 0.5)  # low initial fatigue
        self.soreness = np.random.uniform(0, 0.3)  # low initial soreness
        self.progress_rate = 0.0  # how fast the athlete is progressing
        self.days_since_rest = 0  # number of consecutive workout days
        self.body_weight = np.random.uniform(50, 120)
        self.pr_bench = self.body_weight
        self.pr_squat = 1.25 * self.body_weight
        self.pr_dead = 1.5 * self.body_weight
        self.days_till_competition = np.random.uniform(60, 100)

    def reset(self, seed=None, options=None):
        # Set the seed for reproducibility (if provided)
        super().reset(seed=seed)
        np.random.seed(seed)

        # Reset the athlete's state at the start of a new episode
        self.current_strength = np.random.uniform(0.5, 1.0)
        self.fatigue_level = np.random.uniform(0, 0.5)
        self.soreness = np.random.uniform(0, 0.3)
        self.progress_rate = 0.0
        self.days_since_rest = 0
        
        # Normalize and return the state as the initial observation
        self.state = np.array([self.current_strength, self.fatigue_level, self.soreness, self.progress_rate, self.days_since_rest])
        return self.state, {}

    def step(self, action):
        # Execute the action and update the athlete's state accordingly
        done = False
        reward = 0

        # changes in values for curr_strength etc will also depend on days till competition
        # divide the time line into initial, bulk and final phases
        # eg: final phases will have very less no of reps

        # Handle each action
        if action == 0:  # Decrease weight
            self.current_strength -= 0.01  # slight decrease in strength if reducing weight
            self.fatigue_level -= 0.1  # less fatigue
            self.progress_rate -= 0.02  # slower progress
        elif action == 1:  # Increase weight
            self.current_strength += 0.02  # increase strength
            self.fatigue_level += 0.2  # more fatigue
            self.progress_rate += 0.05  # faster progress
            self.soreness += 0.1  # more soreness from heavier weight
        elif action == 2:  # Rest day
            self.fatigue_level -= 0.3  # fatigue recovery
            self.soreness -= 0.2  # recover soreness
            self.progress_rate -= 0.01  # slight progress drop (no lifting)
            self.days_since_rest = 0  # reset rest counter

        # Increment the days since last rest (if not resting)
        if action != 2:
            self.days_since_rest += 1

        # Normalize the state values (between 0 and 1)
        self.current_strength = np.clip(self.current_strength, 0, 1)
        self.fatigue_level = np.clip(self.fatigue_level, 0, 1)
        self.soreness = np.clip(self.soreness, 0, 1)

        # Calculate the new state
        self.state = np.array([self.current_strength, self.fatigue_level, self.soreness, self.progress_rate, self.days_since_rest])

        # Define reward: balance strength gain with low fatigue and soreness
        reward = self.current_strength * 0.5 - (self.fatigue_level + self.soreness) * 0.25

        # End the episode if the athlete is overtrained or max strength is reached
        if self.fatigue_level >= 1 or self.soreness >= 1:
            done = True  # terminate if athlete is exhausted or injured
            reward -= 1  # heavy penalty for overtraining

        return self.state, reward, done, {}, {}

    def render(self, mode='human'):
        # Optionally print the current state for visualization
        print(f"Strength: {self.current_strength}, Fatigue: {self.fatigue_level}, Soreness: {self.soreness}, Progress Rate: {self.progress_rate}, Days Since Rest: {self.days_since_rest}")

env = PowerliftingEnv()
model = PPO('MlpPolicy', env, verbose=1)
model.learn(total_timesteps=10000)

# Use the trained model to suggest workout schedules
obs, _ = env.reset()
schedule = []  # List to store the workout schedule

for _ in range(100):
    # 1. Based on current stat, suggest appropriate action
    action, _states = model.predict(obs)

    # 2. Based on the action, current day's schedule is given to user

    # 3. Athlete workout with suggested schedule, provides feedback

    # 4. Based on feedback, athlete's stats are updated
    obs, rewards, dones, truncated, info = env.step(action)
    
    # Convert action to readable schedule
    if action == 0:
        schedule.append("Decrease weight")
    elif action == 1:
        schedule.append("Increase weight")
    elif action == 2:
        schedule.append("Rest day")
    
    # End the episode if done or truncated
    if dones or truncated:
        break  # Stop after an episode ends

# Print the schedule
print("Workout Schedule:")
for day, action in enumerate(schedule, start=1):
    print(f"Day {day}: {action}")
