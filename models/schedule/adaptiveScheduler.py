import random
import numpy as np

# Athlete stats
athlete_stats = {
    "age": 30,
    "weight": 80,
    "gender": "Male",
    "bestSquat": 150,
    "bestBench": 80,
    "bestDeadlift": 180,
    "targetSquat": 220,
    "targetBench": 110,
    "targetDeadlift": 250,
    "duration": 60,  # days
}

exercise_to_stat_map = {
    "squat": "bestSquat",
    "bench_press": "bestBench",
    "deadlift": "bestDeadlift",
    "seated_leg_curl": "bestSquat",
    "bulgarian_split_squat": "bestSquat",
    "barbell_row": "bestDeadlift",
    "pause_deadlift": "bestDeadlift",
    "lat_pulldown": "bestBench",
    "dumbbell_lateral_raise": "bestBench",
}

actions = ["increase", "decrease"]

# Q-learning adjustment function
def adjust_params(params, feedback):
    max_weight = int(athlete_stats[exercise_to_stat_map[params["exercise"]]] * 1.1) 
    min_weight = 10  # Minimum weight

    if feedback == "optimal":
        params["weight"] = min(params["weight"] + 5, max_weight)
        params["sets"] = min(params["sets"] + 1, 6)
    elif feedback in ["fatigue", "incomplete"]:
        params["weight"] = max(params["weight"] - 5, min_weight)
        params["sets"] = max(params["sets"] - 1, 2)

# Generate initial factors using Q-learning
def update_factor_q_learning(exercise, initial_factor, best_value, target_value, duration):
    factor = initial_factor
    state = (exercise, factor)
    q_values = {}

    for _ in range(10000):
        action = random.choice(actions)
        if action == "increase":
            factor += 0.01
        elif action == "decrease":
            factor -= 0.01

        factor = np.clip(factor, 0.4, 0.8)
        fatigue_penalty = abs(factor - 0.6) * 0.3
        strength_reward = (factor * target_value / best_value) * 0.7
        reward = strength_reward - fatigue_penalty

        next_state = (exercise, factor)
        max_next_q = max(q_values.get((next_state, a), 0) for a in actions)
        q_values[(state, action)] = q_values.get((state, action), 0) + \
                                    0.1 * (reward + 0.9 * max_next_q - q_values.get((state, action), 0))
        state = next_state

    return round(factor, 2)

# Calculate factors for all exercises
exercise_factors = {}
for exercise in exercise_to_stat_map:
    initial_factor = 0.5
    best_value = athlete_stats[exercise_to_stat_map[exercise]]
    target_value = athlete_stats[exercise_to_stat_map[exercise].replace("best", "target")]
    exercise_factors[exercise] = update_factor_q_learning(
        exercise, initial_factor, best_value, target_value, athlete_stats["duration"]
    )

# Workout schedule with specific exercises
workout_schedule = {
    1: ["squat", "bench_press", "deadlift"],
    2: ["squat", "bench_press", "deadlift", "seated_leg_curl", "bulgarian_split_squat"],
    3: "Rest",  # Rest Day
    4: ["squat", "bench_press", "deadlift", "barbell_row", "pause_deadlift"],  # Fixed exercises
    5: "Rest",  # Rest Day
    6: ["squat", "bench_press", "deadlift", "lat_pulldown", "dumbbell_lateral_raise"],  # Fixed exercises
    7: "Rest",  # Rest Day
}

# Dictionary to store updated exercise parameters
updated_params = {}

# Function to generate workout
def generate_workout(day):
    if workout_schedule[day] == "Rest":
        return "Rest"

    exercises = workout_schedule[day]
    return {
        exercise: updated_params.get(
            exercise,
            {
                "exercise": exercise,
                "weight": int(athlete_stats[exercise_to_stat_map[exercise]] * exercise_factors[exercise]),
                "sets": 4,
                "reps": 8 if "deadlift" not in exercise else 6,
            },
        )
        for exercise in exercises
    }

# Main loop for 60 days
for day in range(1, athlete_stats["duration"] + 1):
    day_of_cycle = (day - 1) % 7 + 1  # Cycle repeats every 7 days

    print(f"\nDay {day} Plan:")
    
    if workout_schedule[day_of_cycle] == "Rest":
        print("Rest Day. No workout scheduled.")
        continue  # Skip feedback for rest days

    daily_workout = generate_workout(day_of_cycle)

    for exercise, params in daily_workout.items():
        print(f"{exercise.replace('_', ' ').capitalize()}: {params['sets']} sets of {params['reps']} reps at {params['weight']} kg")

    # Collect feedback
    feedback = {}
    for exercise in daily_workout:
        feedback[exercise] = input(f"Did you complete the {exercise.replace('_', ' ')} exercises? (optimal/fatigue/incomplete): ").strip().lower()

    # Adjust workout based on feedback
    for exercise, params in daily_workout.items():
        adjust_params(params, feedback[exercise])
        updated_params[exercise] = params  # Save updated parameters

    print("\nUpdated Workout Schedule:")
    for exercise, params in daily_workout.items():
        print(f"{exercise.replace('_', ' ').capitalize()}: {params['sets']} sets of {params['reps']} reps at {params['weight']} kg")
