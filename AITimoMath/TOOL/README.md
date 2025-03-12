# TIMO Question Parser Tool

## Overview
This tool is designed to parse TIMO math questions from text files and convert them to the JSON format required by the AITimoMath app. It provides a user-friendly interface for selecting text files, parsing questions, and saving them to the `timo_questions.json` file.

## Features
- Parse text files containing TIMO math questions
- Extract questions organized by subject
- Convert questions to the proper JSON format
- Preview parsed questions and generated JSON
- Save directly to the app's question bank or export to a custom location

## Text File Format
The tool expects text files in the following format:

```
### Subject Name
#Q1
Content of question 1
A. Option 1
B. Option 2
C. Option 3
D. Option 4

#Q2
Content of question 2
A. Option 1
B. Option 2
C. Option 3
D. Option 4

### Another Subject
#Q3
Content of question 3
A. Option 1
B. Option 2
C. Option 3
D. Option 4
```

- Subject headers are marked with `###`
- Questions start with `#Q` followed by a number
- Question content follows until the next question or subject
- Options are marked with A., B., C., D.

## Usage

### macOS Version (Recommended)
1. Open Terminal
2. Navigate to the TOOL directory
3. Run the macOS version of the tool:
   ```
   ./run_mac.sh
   ```
4. Use the GUI to select a text file, parse questions, and save the JSON

### iOS Version
1. Open Xcode
2. Open the TIMOQuestionParser.xcodeproj file
3. Build and run the project on an iOS simulator or device
4. Use the GUI to select a text file, parse questions, and save the JSON

## Sample Files
- `sample_questions.txt`: A sample text file with TIMO questions for testing the parser

## Directory Structure
- `TIMOQuestionParserApp.swift`: Main app file for iOS
- `TIMOQuestionParserMac.swift`: macOS version of the tool
- `Models/`: Contains the question parser and file manager
- `Views/`: Contains the UI components
- `ViewModels/`: Contains the view models for the UI
- `run.sh`: Script to build and run the iOS version
- `run_mac.sh`: Script to build and run the macOS version
- `sample_questions.txt`: Sample text file for testing

## Requirements
- macOS 12.0 or later (for macOS version)
- iOS 15.0 or later (for iOS version)
- Swift 5.5 or later
- Xcode 13.0 or later (for iOS version)

## License
This tool is part of the AITimoMath project and is subject to the same license terms. 