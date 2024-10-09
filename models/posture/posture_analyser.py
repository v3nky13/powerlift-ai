import cv2
import mediapipe as mp

# Initialize pose estimation model
mp_pose = mp.solutions.pose
pose = mp_pose.Pose()

cap = cv2.VideoCapture('squat_video.mp4')

# Get frame rate
frame_rate = cap.get(cv2.CAP_PROP_FPS)
if frame_rate == 0 or frame_rate is None:
    frame_rate = 30  # Default to 30 FPS

frame_interval = max(1, int(frame_rate // 30))  # Ensure it's at least 1
frame_count = 0
paused = False

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

        # Save frame every 'frame_interval' frames
        if frame_count % frame_interval == 0:
            cv2.imwrite(f'frames/frame_{frame_count}.jpg', frame)

        frame_count += 1

    # Listen for key presses
    key = cv2.waitKey(30) & 0xFF
    if key == ord('q'):  # Quit the video by pressing 'q'
        break
    elif key == ord('p'):  # Pause/resume the video by pressing 'p'
        paused = not paused

cap.release()
cv2.destroyAllWindows()