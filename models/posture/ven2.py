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

cap = cv2.VideoCapture('videos/sv3.mp4')

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
# Additional variables for feedback and skeletal highlight color
feedback = ""
skeletal_color = (0, 255, 0)  # Default skeletal color (Green)

while cap.isOpened():
    if not paused:
        ret, frame = cap.read()
        if not ret:
            break

        # Convert the frame to RGB for pose detection
        img_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = pose.process(img_rgb)

        if result.pose_landmarks:
            points = {}
            for name, landmark_id in essential_landmarks.items():
                landmark = result.pose_landmarks.landmark[landmark_id]
                x, y = int(landmark.x * frame.shape[1]), int(landmark.y * frame.shape[0])
                points[name] = (x, y)
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

            if currSquatPhase == SquatPhase.DESCENT:
                kneeAngle = calculate_angle(points['left_hip'], points['left_knee'], points['left_ankle'])

            # Check if squat reaches sufficient depth
                if kneeAngle < 95 and bottomSquatPosition is None:
                    currSquatPhase = SquatPhase.BOTTOM
                    phase_frames.append(frame_count)
                    bottomSquatPosition = points['left_shoulder'][1]
                    lowestKneeAngle = kneeAngle
                    print(f'BOTTOM phase at frame {frame_count} ({bottomSquatPosition = })')

                    # Squat is proper
                    feedback = "Good squat depth!"
                    skeletal_color = (0, 255, 0)  # Green for correct squat
                elif frame_count - phase_frames[-1] > frame_rate:  # Timeout if depth not reached
                    feedback = "Squat depth insufficient! Improve knee angle."
                    skeletal_color = (0, 0, 255)  # Red for incorrect squat

                    # Capture the current frame
                    improper_frame = frame.copy()

                    # Highlight skeletal structure in red
                    cv2.line(improper_frame, points['left_shoulder'], points['left_hip'], skeletal_color, 2)
                    cv2.line(improper_frame, points['left_hip'], points['left_knee'], skeletal_color, 2)
                    cv2.line(improper_frame, points['left_knee'], points['left_ankle'], skeletal_color, 2)

                    cv2.line(improper_frame, points['right_shoulder'], points['right_hip'], skeletal_color, 2)
                    cv2.line(improper_frame, points['right_hip'], points['right_knee'], skeletal_color, 2)
                    cv2.line(improper_frame, points['right_knee'], points['right_ankle'], skeletal_color, 2)

                    # Overlay feedback text
                    cv2.putText(improper_frame, feedback, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, skeletal_color, 2, cv2.LINE_AA)

                    # Show the frame with insufficient depth
                    cv2.imshow('Improper Squat', improper_frame)
                    cv2.waitKey(0)  # Wait for a key press to close the window

                    print(f'IMPROPER SQUAT: Depth not reached at frame {frame_count}')
                    break  # Exit the loop
                '''elif frame_count - phase_frames[-1] > frame_rate:  # Timeout if depth not reached
                    feedback = "Squat depth insufficient! Improve knee angle."
                    skeletal_color = (0, 0, 255)  # Red for incorrect squat
                    print(f'IMPROPER SQUAT: Depth not reached at frame {frame_count}')
                    break  # End squat analysis here'''

            '''if currSquatPhase == SquatPhase.DESCENT and kneeAngle < 90 and bottomSquatPosition is None:
                currSquatPhase = SquatPhase.BOTTOM
                phase_frames.append(frame_count)
                bottomSquatPosition = points['left_shoulder'][1]
                lowestKneeAngle = kneeAngle
                print(f'BOTTOM phase at frame {frame_count} ({bottomSquatPosition = })')

                # Check squat depth quality
                if kneeAngle < 90:
                    feedback = "Good squat depth!"
                    skeletal_color = (0, 255, 0)  # Green for correct squat
                else:
                    feedback = "Improve depth or knee position!"
                    skeletal_color = (0, 0, 255)  # Red for incorrect squat'''

            if currSquatPhase == SquatPhase.BOTTOM and kneeAngle > 90:
                currSquatPhase = SquatPhase.ASCENT
                phase_frames.append(frame_count)
                print(f'ASCENT phase at frame {frame_count}')

            if currSquatPhase == SquatPhase.ASCENT and kneeAngle > 170:
                currSquatPhase = SquatPhase.END
                phase_frames.append(frame_count)
                print(f'END phase at frame {frame_count}')

            knee_angles.append(kneeAngle)

            # Draw lines connecting the key points with dynamic skeletal color
            cv2.line(frame, points['left_shoulder'], points['left_hip'], skeletal_color, 2)
            cv2.line(frame, points['left_hip'], points['left_knee'], skeletal_color, 2)
            cv2.line(frame, points['left_knee'], points['left_ankle'], skeletal_color, 2)

            cv2.line(frame, points['right_shoulder'], points['right_hip'], skeletal_color, 2)
            cv2.line(frame, points['right_hip'], points['right_knee'], skeletal_color, 2)
            cv2.line(frame, points['right_knee'], points['right_ankle'], skeletal_color, 2)

            # Display feedback on the video frame
            cv2.putText(frame, feedback, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, skeletal_color, 2, cv2.LINE_AA)

        cv2.imshow('Squat Analysis', frame)
        frame_count += 1

    key = cv2.waitKey(30) & 0xFF
    if key == ord('q'):
        break
    elif key == ord('p'):
        paused = not paused

cap.release()
cv2.destroyAllWindows()

plt.plot(knee_angles)
for x in phase_frames:
    plt.axvline(x=x, color='g', linestyle='-')
plt.title('Squat Knee Angle vs. Frame')
plt.grid(True)
plt.show()