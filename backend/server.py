import os
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

import pickle
from tensorflow import keras
import cv2
import numpy as np
import mediapipe as mp
from enum import Enum
from flask import Flask, request, jsonify, send_file
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from langchain_groq import ChatGroq
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from dotenv import load_dotenv
from datetime import datetime

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'
app.config['SECRET_KEY'] = 'your_secret_key'

db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'
currUserId = None

class User(db.Model, UserMixin):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False)
    email = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)
    dob = db.Column(db.String(50), nullable=False)
    height = db.Column(db.Float, nullable=False)
    weight = db.Column(db.Float, nullable=False)
    squatPR = db.Column(db.Float, nullable=False)
    benchPR = db.Column(db.Float, nullable=False)
    deadliftPR = db.Column(db.Float, nullable=False)
    gender = db.Column(db.String(50), nullable=False)
    experienceLevel = db.Column(db.String(50), nullable=False)
    equipment = db.Column(db.String(50), nullable=False)

    goal_squat_weight = db.Column(db.Float, nullable=True)
    goal_bench_weight = db.Column(db.Float, nullable=True)
    goal_deadlift_weight = db.Column(db.Float, nullable=True)
    goal_date = db.Column(db.String(50), nullable=True)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = bcrypt.generate_password_hash(data.get('password')).decode('utf-8')
    dob = data.get('dob')
    height = float(data.get('height'))
    weight = float(data.get('weight'))
    squatPR = float(data.get('squatPR'))
    benchPR = float(data.get('benchPR'))
    deadliftPR = float(data.get('deadliftPR'))
    gender = data.get('gender')
    experienceLevel = data.get('experienceLevel')
    equipment = data.get('equipment')
    
    user = User(name=name, email=email, password=password, dob=dob, height=height, weight=weight,
                squatPR=squatPR, benchPR=benchPR, deadliftPR=deadliftPR, gender=gender,
                experienceLevel=experienceLevel, equipment=equipment)
    db.session.add(user)
    db.session.commit()
    print("User registered successfully")
    return jsonify({'message': 'User registered successfully'}), 201

@app.route('/login', methods=['POST'])
def login():
    global currUserId
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    user = User.query.filter_by(email=email).first()
    if user and bcrypt.check_password_hash(user.password, password):
        login_user(user)
        currUserId = user.id
        return jsonify({'message': 'Login successful', 'name': user.name}), 200
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/logout', methods=['POST'])
def logout():
    global currUserId
    logout_user()
    currUserId = None
    return jsonify({'message': 'Logged out successfully'}), 200

@app.route('/get_user', methods=['GET'])
def get_user():
    user = User.query.filter_by(id=currUserId).first()
    squatScore = round(user.squatPR / 365 * 100)
    benchScore = round(user.benchPR / 315 * 100)
    deadliftScore = round(user.deadliftPR / 340 * 100)
    overallScore = round((squatScore + benchScore + deadliftScore) / 3)
    user_data = {
        'name': user.name,
        'email': user.email,
        'dob': user.dob,
        'height': user.height,
        'weight': user.weight,
        'squatPR': user.squatPR,
        'benchPR': user.benchPR,
        'deadliftPR': user.deadliftPR,
        'gender': user.gender,
        'experienceLevel': user.experienceLevel,
        'equipment': user.equipment,
        'squatScore': squatScore,
        'benchScore': benchScore,
        'deadliftScore': deadliftScore,
        'overallScore': overallScore
    }
    return jsonify(user_data)

@app.route('/update_user', methods=['POST'])
@login_required
def update_user():
    data = request.get_json()
    current_user.name = data.get('name', current_user.name)
    current_user.dob = data.get('dob', current_user.dob)
    current_user.height = float(data.get('height', current_user.height))
    current_user.weight = float(data.get('weight', current_user.weight))
    current_user.squatPR = float(data.get('squatPR', current_user.squatPR))
    current_user.benchPR = float(data.get('benchPR', current_user.benchPR))
    current_user.deadliftPR = float(data.get('deadliftPR', current_user.deadliftPR))
    current_user.gender = data.get('gender', current_user.gender)
    current_user.experienceLevel = data.get('experienceLevel', current_user.experienceLevel)
    current_user.equipment = data.get('equipment', current_user.equipment)
    db.session.commit()
    return jsonify({'message': 'User data updated successfully'})

@app.route('/set_goal', methods=['POST'])
def set_goal():
    try:
        data = request.get_json()

        # Fetch the user from the database
        user = User.query.get(currUserId)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Update user goal fields
        user.goal_squat_weight = float(data.get('goal_squat_weight'))
        user.goal_bench_weight = float(data.get('goal_bench_weight'))
        user.goal_deadlift_weight = float(data.get('goal_deadlift_weight'))
        user.goal_date = data.get('goal_date')
        user.goal_event = data.get('goal_event')

        db.session.commit()
        print("Goal set successfully")
        return jsonify({'message': 'Goal set successfully!'}), 200

    except Exception as e:
        print("Error:", str(e))  # Log error
        return jsonify({'error': str(e)}), 500

@app.route('/get_rank_score', methods=['POST'])
def get_rank_score():
    global currUserId

    data = request.get_json()
    event_id = data.get('event_id')
    event_date = data.get('event_date')
    print("Event ID:", event_id)
    print("Event Date:", event_date)
    print("Current User ID:", currUserId)

    user = User.query.filter_by(id=currUserId).first()

    dob = datetime.strptime(user.dob, '%Y-%m-%d')
    event_date = datetime.strptime(f'{event_date} 2025', '%d %b %Y')
    today = datetime.today()
    age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
    diffDays = (event_date - today).days

    score_scaler = pickle.load(open("score_scaler.pkl", "rb"))
    score_model = keras.models.load_model('score_model.h5')

    score_input_scaled = score_scaler.transform([[
        1 if user.gender == 'Male' else 0,
        1 if user.equipment == 'Equipped' else 0,
        age,
        user.weight,
        user.squatPR,
        user.benchPR,
        user.deadliftPR,
        diffDays,
        1 if user.equipment == 'Equipped' else 0,
        age,
        user.weight
    ]])

    score_pred = score_model.predict(score_input_scaled)

    rank_scaler = pickle.load(open("rank_scaler.pkl", "rb"))
    rank_model_params = pickle.load(open("rank_model.pkl", "rb"))

    W = rank_model_params['W']
    b = rank_model_params['b']
    beta = rank_model_params['beta']

    def rc_elm_predict(X, W, b, beta):
        H = np.tanh(np.dot(X, W.T) + b)
        return np.dot(H, beta)

    rank_input_scaled = rank_scaler.transform([[
        0 if user.gender == 'Male' else 1,
        0 if event_id == 2 else 1,
        2 if event_id in [4, 5] else 0 if age <= 19 else 1,
        user.weight,
        score_pred[0][0],
        score_pred[0][1],
        score_pred[0][2]
    ]])

    rank_pred = rc_elm_predict(rank_input_scaled, W, b, beta)

    rank_score = f"{round(int(rank_pred[0][0]))}"
    default_squat_weight = str(int(round(score_pred[0][0] / 5)) * 5)
    default_bench_weight = str(int(round(score_pred[0][1] / 5)) * 5)
    default_deadlift_weight = str(int(round(score_pred[0][2] / 5)) * 5)

    return jsonify({
        'rank_score': rank_score,
        'default_squat_weight': default_squat_weight,
        'default_bench_weight': default_bench_weight,
        'default_deadlift_weight': default_deadlift_weight
    })

with app.app_context():
    db.create_all()

# Load API key for Groq LLM
load_dotenv()
GROQ_API_KEY = os.getenv("GROQ_API_KEY")

if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY is not set. Check your environment variables or .env file.")

# Initialize LLM
llm = ChatGroq(
    model="llama-3.3-70b-versatile",
    api_key=GROQ_API_KEY,
    temperature=0,
    streaming=True
)

# Load saved ChromaDB embeddings
embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-mpnet-base-v2")
vector_store = Chroma(persist_directory="./chroma_db", embedding_function=embeddings)

# API endpoint to handle user queries
@app.route("/chat", methods=["POST"])
def chat():
    print('Hit route')  
    data = request.json
    user_question = data.get("question", "")

    if not user_question:
        return jsonify({"error": "Question is required"}), 400

    # Perform similarity search
    retrieved_docs = vector_store.similarity_search(user_question, k=3)
    context = "\n".join([doc.page_content for doc in retrieved_docs])

    # Construct prompt
    prompt = f"""
    You are an assistant for powerlifting. Answer questions using the context below.
    If you don't know, just say you don't know, while providing answer give in bullet points.
    
    Context:
    {context}

    Question: {user_question}
    Answer:
    """

    response = llm.invoke(prompt).content
    return jsonify({"response": response})

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
    #input_video_path = "uploaded_video.mp4"
    #output_video_path = "analyzed_video.mp4"
    input_video_path = os.path.join(os.getcwd(), "uploaded_video.mp4")
    output_video_path = os.path.join(os.getcwd(), "analyzed_video.mp4")
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