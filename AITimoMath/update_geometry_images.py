#!/usr/bin/env python3
import json
import os

# Path to the JSON file
json_file_path = 'AITimoMath/Data/timo_questions.json'

# Read the JSON file
with open(json_file_path, 'r') as file:
    data = json.load(file)

# Count how many questions were updated
updated_count = 0

# Update the imageData field for all Geometry questions
for question in data['questions']:
    if question['subject'] == 'Geometry':
        question_id = question['id']
        # Check if content exists
        if 'content' in question:
            # Add or update the imageData field
            question['content']['imageData'] = question_id
            updated_count += 1
            print(f'Updated imageData for {question_id}')

# Write the updated JSON back to the file
with open(json_file_path, 'w') as file:
    json.dump(data, file, indent=2)

print(f'Successfully updated imageData for {updated_count} Geometry questions in {json_file_path}') 