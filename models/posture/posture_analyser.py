import cv2
import mediapipe as mp
from enum import Enum
import numpy as np
from matplotlib import pyplot as plt

class SquatPhase(Enum):
    START = 1
    DESCENT = 2
    BOTTOM = 3
    ASCENT = 4
    END = 5

def calculate_angle(a, b, c):
    ba = np.array(a) - np.array(b)  # Vector from hip to shoulder
    bc = np.array(c) - np.array(b)  # Vector from hip to knee
    
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    angle = np.arccos(cosine_angle)
    return np.degrees(angle)

# Initialize pose estimation model
mp_pose = mp.solutions.pose
pose = mp_pose.Pose()

# List of essential landmark indices for squat analysis
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

cap = cv2.VideoCapture('videos/sv1.mp4')

# Get frame rate
frame_rate = cap.get(cv2.CAP_PROP_FPS)
if frame_rate == 0 or frame_rate is None:
    frame_rate = 30  # Default to 30 FPS

frame_interval = max(1, int(frame_rate // 30))  # Ensure it's at least 1
frame_count = 0
paused = False

currSquatPhase = SquatPhase.START
print('START')
topSquatPosition = None
bottomSquatPosition = None
lowestKneeAngle = None

knee_angles = []
phase_frames = [0]

while cap.isOpened():
    if not paused:
        ret, frame = cap.read()
        if not ret:
            break

        # Convert the frame to RGB for pose detection
        img_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = pose.process(img_rgb)

        if result.pose_landmarks:
            # Dictionary to store the (x, y) coordinates of essential landmarks
            points = {}

            # Extract only the essential landmarks for squat analysis
            for name, landmark_id in essential_landmarks.items():
                landmark = result.pose_landmarks.landmark[landmark_id]
                x, y = int(landmark.x * frame.shape[1]), int(landmark.y * frame.shape[0])
                points[name] = (x, y)
                # Draw circles at the key points
                cv2.circle(frame, (x, y), 5, (255, 0, 0), -1)

            if topSquatPosition is None:
                topSquatPosition = points['left_shoulder'][1]
                phase_frames.append(frame_count)
                print(f'START phase at frame 0 ({topSquatPosition = })')
            
            if currSquatPhase == SquatPhase.START and points['left_shoulder'][1] > topSquatPosition * 1.05:
                currSquatPhase = SquatPhase.DESCENT
                phase_frames.append(frame_count)
                print(f'DESCENT phase at frame {frame_count}')
            
            kneeAngle = calculate_angle(points['left_hip'], points['left_knee'], points['left_ankle'])

            if currSquatPhase == SquatPhase.DESCENT and kneeAngle < 90 and bottomSquatPosition is None:
                currSquatPhase = SquatPhase.BOTTOM
                phase_frames.append(frame_count)
                bottomSquatPosition = points['left_shoulder'][1]
                lowestKneeAngle = kneeAngle
                print(f'BOTTOM phase at frame {frame_count} ({bottomSquatPosition = })')
            
            # if currSquatPhase == SquatPhase.BOTTOM and kneeAngle < lowestKneeAngle:
            #     lowestKneeAngle = kneeAngle
            #     bottomSquatPosition = points['left_shoulder'][1]
            #     phase_frames.append(frame_count)
            
            if currSquatPhase == SquatPhase.BOTTOM and kneeAngle > 90:
                currSquatPhase = SquatPhase.ASCENT
                phase_frames.append(frame_count)
                print(f'ASCENT phase at frame {frame_count}')
            
            if currSquatPhase == SquatPhase.ASCENT and kneeAngle > 170:
                currSquatPhase = SquatPhase.END
                phase_frames.append(frame_count)
                print(f'END phase at frame {frame_count}')

            knee_angles.append(kneeAngle)

            # Draw lines connecting the key points
            # Left side (shoulder -> hip -> knee -> ankle)
            cv2.line(frame, points['left_shoulder'], points['left_hip'], (0, 255, 0), 2)
            cv2.line(frame, points['left_hip'], points['left_knee'], (0, 255, 0), 2)
            cv2.line(frame, points['left_knee'], points['left_ankle'], (0, 255, 0), 2)

            # Right side (shoulder -> hip -> knee -> ankle)
            cv2.line(frame, points['right_shoulder'], points['right_hip'], (0, 255, 0), 2)
            cv2.line(frame, points['right_hip'], points['right_knee'], (0, 255, 0), 2)
            cv2.line(frame, points['right_knee'], points['right_ankle'], (0, 255, 0), 2)

        # Display the current frame
        cv2.imshow('Squat Analysis', frame)

        frame_count += 1

    # Listen for key presses
    key = cv2.waitKey(30) & 0xFF
    if key == ord('q'):  # Quit the video by pressing 'q'
        break
    elif key == ord('p'):  # Pause/resume the video by pressing 'p'
        paused = not paused

cap.release()
cv2.destroyAllWindows()

# print(f'{shk_angles_left = }\n\n{hka_angles_left = }')

plt.plot(knee_angles)
for x in phase_frames:
    plt.axvline(x=x, color='g', linestyle='-')
plt.title('Squat Knee Angle vs. Frame')
plt.grid(True)
plt.show()