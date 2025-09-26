#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
CoreML Model Training Script for TIMO Math Adaptive Learning

This script trains machine learning models for the adaptive learning system:
1. Question Recommender - Suggests questions based on student profile
2. Ability Estimator - Estimates student ability from response patterns
3. Difficulty Predictor - Predicts question difficulty for a student

Models are trained using historical question data and saved in CoreML format.
"""

import json
import os
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier, GradientBoostingRegressor
from sklearn.metrics import accuracy_score, mean_squared_error
import coremltools as ct

# Constants
INPUT_DATA_PATH = "../Data/timo_questions.json"
OUTPUT_MODEL_DIR = "../Resources/MLModels"
RANDOM_SEED = 42

def load_question_data(json_path):
    """Load question data from JSON file"""
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"Loaded {len(data['questions'])} questions from {json_path}")
        return data['questions']
    except Exception as e:
        print(f"Error loading data: {e}")
        return []

def preprocess_question_data(questions):
    """Preprocess question data for model training"""
    # Extract features from questions
    question_features = []
    for q in questions:
        # Get subject as one-hot encoded
        subject_mapping = {
            "Logical Thinking": [1, 0, 0, 0, 0],
            "Arithmetic": [0, 1, 0, 0, 0],
            "Number Theory": [0, 0, 1, 0, 0],
            "Geometry": [0, 0, 0, 1, 0],
            "Combinatorics": [0, 0, 0, 0, 1]
        }
        subject_vec = subject_mapping.get(q['subject'], [0, 0, 0, 0, 0])
        
        # Map difficulty to numerical value
        difficulty_mapping = {
            "Easy": 1,
            "Medium": 2,
            "Hard": 3,
            "Olympiad": 4
        }
        difficulty = difficulty_mapping.get(q['difficulty'], 2)
        
        # Extract Elo rating if available, or use default
        elo_rating = 1200
        if 'parameters' in q and 'eloRating' in q['parameters']:
            elo_rating = q['parameters']['eloRating']
            
        # Extract IRT parameters if available, or use defaults
        irt_discrimination = 1.0
        irt_difficulty = 0.0
        irt_guessing = 0.25
        
        if 'parameters' in q and 'irt' in q['parameters']:
            irt_params = q['parameters']['irt']
            irt_discrimination = irt_params.get('discrimination', 1.0)
            irt_difficulty = irt_params.get('difficulty', 0.0)
            irt_guessing = irt_params.get('guessing', 0.25)
        
        # Get question type as binary feature (0 = multiple choice, 1 = open-ended)
        is_open_ended = 1 if q['type'] == 'open-ended' else 0
        
        # Get question length as proxy for complexity
        question_length = len(q['content']['question'])
        
        question_features.append({
            'id': q['id'],
            'subject_logical': subject_vec[0],
            'subject_arithmetic': subject_vec[1],
            'subject_numbertheory': subject_vec[2],
            'subject_geometry': subject_vec[3],
            'subject_combinatorics': subject_vec[4],
            'difficulty': difficulty,
            'is_open_ended': is_open_ended,
            'question_length': question_length,
            'elo_rating': elo_rating,
            'irt_discrimination': irt_discrimination,
            'irt_difficulty': irt_difficulty,
            'irt_guessing': irt_guessing
        })
    
    return pd.DataFrame(question_features)

def generate_synthetic_student_data(question_df, n_students=50):
    """Generate synthetic student response data for model training"""
    np.random.seed(RANDOM_SEED)
    
    student_data = []
    for i in range(n_students):
        # Randomly assign student ability (-3 to +3 on IRT scale)
        student_ability = np.random.normal(0, 1)
        
        # Create preferences for subjects (0-1 scale)
        subject_prefs = np.random.dirichlet(np.ones(5)) * 2  # Dirichlet gives sum=1, scale up
        
        # Create response patterns based on ability and question difficulty
        responses = []
        for _, question in question_df.iterrows():
            # Higher ability students answer correctly more often
            # Higher difficulty questions are answered correctly less often
            irt_diff = question['irt_difficulty']
            disc = question['irt_discrimination']
            guess = question['irt_guessing']
            
            # Use IRT formula to calculate probability of correct answer
            z = disc * (student_ability - irt_diff)
            prob_correct = guess + (1 - guess) / (1 + np.exp(-z))
            
            # Adjust probability based on student's subject preference
            subject_idx = np.argmax([
                question['subject_logical'],
                question['subject_arithmetic'],
                question['subject_numbertheory'],
                question['subject_geometry'],
                question['subject_combinatorics']
            ])
            pref_boost = 0.1 * subject_prefs[subject_idx]
            prob_correct = min(0.95, prob_correct + pref_boost)
            
            # Determine if answer is correct
            is_correct = np.random.random() < prob_correct
            
            # Generate synthetic response time (faster for easy questions/high ability)
            base_time = 30  # baseline of 30 seconds
            difficulty_factor = question['difficulty'] * 5  # 5-20 seconds based on difficulty
            ability_factor = 10 * (1 / (1 + np.exp(student_ability)))  # 0-10 seconds based on ability
            random_factor = np.random.uniform(0, 10)  # random variation
            
            response_time = base_time + difficulty_factor - ability_factor + random_factor
            
            # Add noise to make it realistic
            if is_correct:
                response_time *= np.random.uniform(0.8, 1.2)
            else:
                response_time *= np.random.uniform(0.9, 1.5)  # Incorrect answers often take longer
            
            responses.append({
                'student_id': i,
                'question_id': question['id'],
                'is_correct': int(is_correct),
                'response_time': response_time,
                'difficulty': question['difficulty'],
                'subject_idx': subject_idx
            })
        
        student_data.append({
            'student_id': i,
            'ability': student_ability,
            'subject_pref': subject_prefs,
            'responses': responses
        })
    
    # Convert to DataFrame
    response_rows = []
    for student in student_data:
        for response in student['responses']:
            response_row = {
                'student_id': student['student_id'],
                'student_ability': student['ability'],
                'question_id': response['question_id'],
                'is_correct': response['is_correct'],
                'response_time': response['response_time'],
                'difficulty': response['difficulty'],
                'subject_idx': response['subject_idx']
            }
            for j, pref in enumerate(student['subject_pref']):
                response_row[f'subject_pref_{j}'] = pref
            response_rows.append(response_row)
    
    return pd.DataFrame(response_rows)

def train_question_recommender(question_df, response_df):
    """Train the question recommender model"""
    print("Training Question Recommender Model...")
    
    # Create features for recommendation (student preferences and historical responses)
    student_features = []
    recommendations = []
    
    # Group responses by student
    for student_id, group in response_df.groupby('student_id'):
        # Get student's subject preferences
        subject_prefs = [
            group['subject_pref_0'].iloc[0],
            group['subject_pref_1'].iloc[0],
            group['subject_pref_2'].iloc[0],
            group['subject_pref_3'].iloc[0],
            group['subject_pref_4'].iloc[0]
        ]
        
        # Calculate accuracy by subject
        subject_accuracy = {}
        for subject_idx in range(5):
            subject_responses = group[group['subject_idx'] == subject_idx]
            if len(subject_responses) > 0:
                accuracy = subject_responses['is_correct'].mean()
                subject_accuracy[subject_idx] = accuracy
            else:
                subject_accuracy[subject_idx] = 0.5  # Default if no data
        
        # Calculate ability estimate from correctness
        ability_estimate = group['is_correct'].mean() * 2 - 1  # Scale from 0-1 to -1 to 1
        
        # Get correctly answered questions to avoid recommending them again
        correct_questions = set(group[group['is_correct'] == 1]['question_id'])
        
        # Create a row for this student
        student_features.append({
            'student_id': student_id,
            'subject_pref_0': subject_prefs[0],
            'subject_pref_1': subject_prefs[1],
            'subject_pref_2': subject_prefs[2],
            'subject_pref_3': subject_prefs[3],
            'subject_pref_4': subject_prefs[4],
            'subject_acc_0': subject_accuracy.get(0, 0.5),
            'subject_acc_1': subject_accuracy.get(1, 0.5),
            'subject_acc_2': subject_accuracy.get(2, 0.5),
            'subject_acc_3': subject_accuracy.get(3, 0.5),
            'subject_acc_4': subject_accuracy.get(4, 0.5),
            'ability_estimate': ability_estimate,
            'response_count': len(group)
        })
        
        # Find appropriate next questions (challenging but doable)
        for _, question in question_df.iterrows():
            # Skip already answered correctly
            if question['id'] in correct_questions:
                continue
                
            # Calculate match score based on difficulty, student ability and preferences
            subject_idx = np.argmax([
                question['subject_logical'],
                question['subject_arithmetic'],
                question['subject_numbertheory'],
                question['subject_geometry'],
                question['subject_combinatorics']
            ])
            
            # Score higher if:
            # 1. Difficulty matches ability (not too hard, not too easy)
            # 2. Subject matches student preference
            # 3. Subject is a weak area (low accuracy)
            
            difficulty_match = 1.0 - abs(question['irt_difficulty'] - ability_estimate) / 6.0  # Scale to 0-1
            subject_preference = subject_prefs[subject_idx]
            subject_weakness = 1.0 - subject_accuracy.get(subject_idx, 0.5)  # Invert accuracy to get weakness
            
            recommendation_score = (
                0.4 * difficulty_match + 
                0.3 * subject_preference + 
                0.3 * subject_weakness
            )
            
            recommendations.append({
                'student_id': student_id,
                'question_id': question['id'],
                'recommendation_score': recommendation_score
            })
    
    # Convert to DataFrames
    student_df = pd.DataFrame(student_features)
    recommendation_df = pd.DataFrame(recommendations)
    
    # For each student, select the top 20 recommended questions
    top_recommendations = []
    for student_id, group in recommendation_df.groupby('student_id'):
        top_for_student = group.sort_values('recommendation_score', ascending=False).head(20)
        top_recommendations.append(top_for_student)
    
    recommendation_targets = pd.concat(top_recommendations)
    
    # Merge features with targets for training
    training_data = student_df.merge(
        recommendation_targets, 
        on='student_id'
    )
    
    # Prepare features and target for the model
    X = training_data.drop(['student_id', 'question_id', 'recommendation_score'], axis=1)
    y = training_data['recommendation_score']
    
    # Train a regression model to predict recommendation scores
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=RANDOM_SEED)
    
    model = GradientBoostingRegressor(
        n_estimators=100,
        learning_rate=0.1,
        max_depth=3,
        random_state=RANDOM_SEED
    )
    
    model.fit(X_train, y_train)
    
    # Evaluate model
    y_pred = model.predict(X_test)
    mse = mean_squared_error(y_test, y_pred)
    print(f"Question Recommender - Mean Squared Error: {mse:.4f}")
    
    # Convert to CoreML format
    feature_names = list(X.columns)
    coreml_model = ct.converters.sklearn.convert(
        model,
        feature_names,
        'recommendation_score'
    )
    
    # Set metadata - use properties instead of direct attribute assignment
    spec = coreml_model.get_spec()
    spec.description.metadata.shortDescription = "Question Recommender for TIMO Math"
    
    # Create output directory if it doesn't exist
    os.makedirs(OUTPUT_MODEL_DIR, exist_ok=True)
    
    # Save CoreML model
    model_path = os.path.join(OUTPUT_MODEL_DIR, 'QuestionRecommender.mlmodel')
    coreml_model.save(model_path)
    print(f"Question Recommender model saved to {model_path}")
    
    return model

def train_ability_estimator(response_df):
    """Train the ability estimator model"""
    print("Training Ability Estimator Model...")
    
    # Prepare features and target for the model
    feature_cols = [
        'is_correct', 'response_time', 'difficulty', 'subject_idx',
        'subject_pref_0', 'subject_pref_1', 'subject_pref_2', 
        'subject_pref_3', 'subject_pref_4'
    ]
    
    X = response_df[feature_cols]
    y = response_df['student_ability']
    
    # Train test split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=RANDOM_SEED)
    
    # Train a regression model to predict student ability
    model = GradientBoostingRegressor(
        n_estimators=100,
        learning_rate=0.1,
        max_depth=5,
        random_state=RANDOM_SEED
    )
    
    model.fit(X_train, y_train)
    
    # Evaluate model
    y_pred = model.predict(X_test)
    mse = mean_squared_error(y_test, y_pred)
    print(f"Ability Estimator - Mean Squared Error: {mse:.4f}")
    
    # Convert to CoreML format
    coreml_model = ct.converters.sklearn.convert(
        model,
        list(X.columns),
        'ability'
    )
    
    # Set metadata - use properties instead of direct attribute assignment
    spec = coreml_model.get_spec()
    spec.description.metadata.shortDescription = "Student Ability Estimator for TIMO Math"
    
    # Save CoreML model
    model_path = os.path.join(OUTPUT_MODEL_DIR, 'AbilityEstimator.mlmodel')
    coreml_model.save(model_path)
    print(f"Ability Estimator model saved to {model_path}")
    
    return model

def train_difficulty_predictor(question_df, response_df):
    """Train the difficulty predictor model"""
    print("Training Difficulty Predictor Model...")
    
    # Create features for difficulty prediction
    difficulty_features = []
    
    for _, response in response_df.iterrows():
        # Get question features
        question = question_df[question_df['id'] == response['question_id']].iloc[0]
        
        # Create feature row
        difficulty_features.append({
            'student_ability': response['student_ability'],
            'subject_idx': response['subject_idx'],
            'subject_pref': response[f'subject_pref_{int(response["subject_idx"])}'],
            'irt_discrimination': question['irt_discrimination'],
            'irt_difficulty': question['irt_difficulty'],
            'irt_guessing': question['irt_guessing'],
            'is_open_ended': question['is_open_ended'],
            'question_length': question['question_length'],
            # Target: whether the student found it difficult
            # (proxy: incorrect answer or long response time)
            'perceived_difficulty': float(
                not response['is_correct'] or 
                response['response_time'] > 30  # Consider "difficult" if takes > 30s
            )
        })
    
    # Convert to DataFrame
    difficulty_df = pd.DataFrame(difficulty_features)
    
    # Prepare features and target for the model
    X = difficulty_df.drop(['perceived_difficulty'], axis=1)
    y = difficulty_df['perceived_difficulty']
    
    # Train test split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=RANDOM_SEED)
    
    # Train a regression model to predict difficulty
    model = GradientBoostingRegressor(
        n_estimators=100,
        learning_rate=0.1,
        max_depth=4,
        random_state=RANDOM_SEED
    )
    
    model.fit(X_train, y_train)
    
    # Evaluate model
    y_pred = model.predict(X_test)
    mse = mean_squared_error(y_test, y_pred)
    print(f"Difficulty Predictor - Mean Squared Error: {mse:.4f}")
    
    # Convert to CoreML format
    coreml_model = ct.converters.sklearn.convert(
        model,
        list(X.columns),
        'difficulty'
    )
    
    # Set metadata - use properties instead of direct attribute assignment
    spec = coreml_model.get_spec()
    spec.description.metadata.shortDescription = "Question Difficulty Predictor for TIMO Math"
    
    # Save CoreML model
    model_path = os.path.join(OUTPUT_MODEL_DIR, 'DifficultyPredictor.mlmodel')
    coreml_model.save(model_path)
    print(f"Difficulty Predictor model saved to {model_path}")
    
    return model

def main():
    """Main execution function"""
    print("Starting CoreML model training for TIMO Math Adaptive Learning...")
    
    # Load and preprocess question data
    print("Loading and preprocessing question data...")
    questions = load_question_data(INPUT_DATA_PATH)
    question_df = preprocess_question_data(questions)
    print(f"Preprocessed {len(question_df)} questions")
    
    # Generate synthetic student data
    print("Generating synthetic student data...")
    response_df = generate_synthetic_student_data(question_df)
    print(f"Generated synthetic data for {response_df['student_id'].nunique()} students with {len(response_df)} responses")
    
    # Train the models
    print("\n--- Training Models ---")
    recommender_model = train_question_recommender(question_df, response_df)
    print("Question Recommender model trained successfully!")
    
    ability_model = train_ability_estimator(response_df)
    print("Ability Estimator model trained successfully!")
    
    difficulty_model = train_difficulty_predictor(question_df, response_df)
    print("Difficulty Predictor model trained successfully!")
    
    print("\nModel training complete! All models saved to MLModels directory.")

if __name__ == "__main__":
    main()