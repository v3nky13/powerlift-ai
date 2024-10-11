import json

class Athlete:
    def __init__(self, name=None, dob=None, height=None, weight=None,
                 experience=None, gender=None, bestSquat=None, bestBench=None, bestDeadlift=None):
        self.name = name
        self.dob = dob
        self.height = height
        self.weight = weight
        self.experience = experience
        self.gender = gender
        self.bestSquat = bestSquat
        self.bestBench = bestBench
        self.bestDeadlift = bestDeadlift
        self.fatigue = 1
        self.day = 1
    
    def update_stats(self, bestSquat=None, bestBench=None, bestDeadlift=None, weight=None, fatigue=None):
        if bestSquat is not None:
            self.bestSquat = bestSquat
        if bestBench is not None:
            self.bestBench = bestBench
        if bestDeadlift is not None:
            self.bestDeadlift = bestDeadlift
        if weight is not None:
            self.weight = weight
        if fatigue is not None:
            self.fatigue = fatigue
    
    def get_stats(self):
        return {
            "name": self.name,
            "dob": self.dob,
            "height": self.height,
            "weight": self.weight,
            "experience": self.experience,
            "gender": self.gender,
            "bestSquat": self.bestSquat,
            "bestBench": self.bestBench,
            "bestDeadlift": self.bestDeadlift,
            "fatigue": self.fatigue
        }
    
    def save_to_file(self, filename):
        with open(filename, 'w') as f:
            json.dump(self.get_stats(), f, indent=4)

    def load_from_file(self, filename):
        with open(filename, 'r') as f:
            data = json.load(f)
            self.name = data['name']
            self.dob = data['dob']
            self.height = data['height']
            self.weight = data['weight']
            self.experience = data['experience']
            self.gender = data['gender']
            self.bestSquat = data['bestSquat']
            self.bestBench = data['bestBench']
            self.bestDeadlift = data['bestDeadlift']
            self.fatigue = data['fatigue']

class Excersise:
    def __init__(self, name=None, reps=None, sets=None, intensity=None):
        self.name = name
        self.reps = reps
        self.sets = sets
        self.intensity = intensity

class Schedule:
    def __init__(self, athlete=None, targetDate=None, targetSquat=None, targetBench=None, targetDeadlift=None):
        self.athlete = athlete
        self.targetDate = targetDate
        self.targetSquat = targetSquat
        self.targetBench = targetBench
        self.targetDeadlift = targetDeadlift
        self.excercises = []
    
    def get_schedule(self):
        return {
            "athlete": self.athlete,
            "date": self.date
        }
    
athlete = Athlete(
    name="John Doe",
    dob="01-01-1998",
    height=180,
    weight=80,
    experience="Beginner",
    gender="Male",
    bestSquat=70,
    bestBench=40,
    bestDeadlift=90
)

athlete.save_to_file("athlete_stats.json")
