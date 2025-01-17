import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _squatPRController = TextEditingController();
  final TextEditingController _benchPRController = TextEditingController();
  final TextEditingController _deadliftPRController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedExperienceLevel = 'Beginner';

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final email = _emailController.text;
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      final dob = _dobController.text;
      final height = _heightController.text;
      final weight = _weightController.text;
      final squatPR = _squatPRController.text;
      final benchPR = _benchPRController.text;
      final deadliftPR = _deadliftPRController.text;
      final gender = _selectedGender;
      final experienceLevel = _selectedExperienceLevel;

      // Implement your sign-up logic here

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile created for $name')),
      );
      // Navigate back to login page after sign-up
      Navigator.pop(context);
    }
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != DateTime.now()) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign Up',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background image with opacity 0.1
          Opacity(
            opacity: 0.1,
            child: Image.asset(
              'assets/background.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          } else if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          } else if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Male', 'Female']
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ))
                            .toList(),
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _selectDateOfBirth(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dobController,
                            decoration: InputDecoration(
                              labelText: 'Date of Birth',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your date of birth';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _weightController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your body weight';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _squatPRController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Squat PR',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your squat PR';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _benchPRController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Bench PR',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your bench PR';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _deadliftPRController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Deadlift PR',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your deadlift PR';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedExperienceLevel,
                        onChanged: (value) {
                          setState(() {
                            _selectedExperienceLevel = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Experience Level',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Beginner', 'Intermediate']
                            .map((experienceLevel) => DropdownMenuItem(
                                  value: experienceLevel,
                                  child: Text(experienceLevel),
                                ))
                            .toList(),
                      ),
                      SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
