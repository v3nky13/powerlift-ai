from flask import Flask, request, jsonify, send_file
import cv2
import mediapipe as mp
import numpy as np
import os
from matplotlib import pyplot as plt
from enum import Enum

app = Flask(__name__)

class SquatPhase(Enum):
    START = 1
    DESCENT = 2
    BOTTOM = 3
    ASCENT = 4
    END = 5

def calculate_angle(a, b, c):
    ba = np.array(a) - np.array(b)
    bc = np.array(c) - np.array(b)
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    angle = np.arccos(cosine_angle)
    return np.degrees(angle)

@app.route('/analyze', methods=['POST'])
def analyze_squat():
    if 'video' not in request.files:
        return jsonify({'error': 'No video file provided'}), 400

    # Save the uploaded video file
    video_file = request.files['video']
    input_video_path = "uploaded_video.mp4"
    output_video_path = "analyzed_video.mp4"
    video_file.save(input_video_path)

    # Initialize Mediapipe Pose model
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose()
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
    cap = cv2.VideoCapture(input_video_path)
    if not cap.isOpened():
        return jsonify({'error': 'Failed to process the video'}), 500
    frame_rate = cap.get(cv2.CAP_PROP_FPS)
    if frame_rate == 0 or frame_rate is None:
        frame_rate = 30  # Default to 30 FPS

    frame_interval = max(1, int(frame_rate // 30))  # Ensure it's at least 1
    frame_count = 0
    paused = False
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    out = cv2.VideoWriter(output_video_path, fourcc, frame_rate, (frame_width, frame_height))
    
    currSquatPhase = SquatPhase.START
    print('START')
    topSquatPosition = None
    bottomSquatPosition = None
    lowestKneeAngle = None

    knee_angles = []
    phase_frames = [0]
    feedback = ""
    skeletal_color = (0, 255, 0)
    while cap.isOpened():
        if not paused:
            ret, frame = cap.read()
            if not ret:
                break
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
                        feedback = "Squat depth insufficient!"
                        skeletal_color = (0, 0, 255)  # Red for incorrect squat
                        currSquatPhase = SquatPhase.BOTTOM

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

                        print(f'IMPROPER SQUAT: Depth not reached at frame {frame_count}')
                        #break

                if currSquatPhase == SquatPhase.BOTTOM and kneeAngle > 90:
                    currSquatPhase = SquatPhase.ASCENT
                    phase_frames.append(frame_count)
                    print(f'ASCENT phase at frame {frame_count}')

                if currSquatPhase == SquatPhase.ASCENT and kneeAngle > 170:
                    currSquatPhase = SquatPhase.END
                    phase_frames.append(frame_count)
                    print(f'END phase at frame {frame_count}')

                knee_angles.append(kneeAngle)
                cv2.line(frame, points['left_shoulder'], points['left_hip'], skeletal_color, 2)
                cv2.line(frame, points['left_hip'], points['left_knee'], skeletal_color, 2)
                cv2.line(frame, points['left_knee'], points['left_ankle'], skeletal_color, 2)

                cv2.line(frame, points['right_shoulder'], points['right_hip'], skeletal_color, 2)
                cv2.line(frame, points['right_hip'], points['right_knee'], skeletal_color, 2)
                cv2.line(frame, points['right_knee'], points['right_ankle'], skeletal_color, 2)
                cv2.putText(frame, feedback, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, skeletal_color, 2, cv2.LINE_AA)
                
            
            frame_count += 1
            out.write(frame)

    cap.release()
    out.release()
    cv2.destroyAllWindows()

    print("heyyyyyy")

    # Return the processed video file
    return send_file(output_video_path, as_attachment=True)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)