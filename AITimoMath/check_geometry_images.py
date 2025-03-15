#!/usr/bin/env python3
import json
import os

# Path to the JSON file - corrected path
json_file_path = 'AITimoMath/AITimoMath/Data/timo_questions.json'

# Read the JSON file
with open(json_file_path, 'r') as file:
    data = json.load(file)

# Find Geometry questions
geometry_questions = [q for q in data['questions'] if q['subject'] == 'Geometry']
print(f'Total Geometry questions: {len(geometry_questions)}')

# Find questions with missing or incorrect imageData
missing_or_incorrect = []
for q in geometry_questions:
    q_id = q['id']
    if 'content' not in q or 'imageData' not in q['content'] or q['content']['imageData'] != q_id:
        missing_or_incorrect.append(q_id)
        # Update the imageData field
        if 'content' in q:
            q['content']['imageData'] = q_id
            print(f'Updated imageData for {q_id}')

print(f'Questions with missing or incorrect imageData: {len(missing_or_incorrect)}')
if missing_or_incorrect:
    print('IDs with issues:')
    for q_id in missing_or_incorrect:
        print(f'  - {q_id}')

# Write the updated JSON back to the file
with open(json_file_path, 'w') as file:
    json.dump(data, file, indent=2)

print(f'Successfully updated imageData for all Geometry questions in {json_file_path}') 