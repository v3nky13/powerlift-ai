import numpy as np
import mediapipe as mp

# Load the landmarks from the .npy file
landmarks = np.load('squat_points/0.npy', allow_pickle=True)

# Define essential landmarks
mp_pose = mp.solutions.pose

essential_landmarks = {
    'left_shoulder': mp_pose.PoseLandmark.LEFT_SHOULDER,
    'right_shoulder': mp_pose.PoseLandmark.RIGHT_SHOULDER,
    'left_hip': mp_pose.PoseLandmark.LEFT_HIP,
    'right_hip': mp_pose.PoseLandmark.RIGHT_HIP,
    'left_knee': mp_pose.PoseLandmark.LEFT_KNEE,
    'right_knee': mp_pose.PoseLandmark.RIGHT_KNEE,
    'left_ankle': mp_pose.PoseLandmark.LEFT_ANKLE,
    'right_ankle': mp_pose.PoseLandmark.RIGHT_ANKLE
}

# Extract essential landmarks with x, y, z, and visibility
extracted_landmarks = {}

for key, value in essential_landmarks.items():
    if value.value < len(landmarks):
        landmark_data = landmarks[value.value]
        extracted_landmarks[key] = {
            'x': landmark_data[0],
            'y': landmark_data[1],
            'z': landmark_data[2],
            'visibility': landmark_data[3]  # Assuming visibility is the fourth attribute
        }
    else:
        extracted_landmarks[key] = None  # Handle out-of-bounds case

# Print the extracted landmarks
print(extracted_landmarks)
