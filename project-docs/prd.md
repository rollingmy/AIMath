# Product Requirement Document (PRD)

All gerenated folders / files are in the @AITimoMath folder.

## **Project: Adaptive Learning Engine for TIMO Math Lessons**

### **1. Overview**
The Adaptive Learning Engine for TIMO Math Lessons is an AI-driven educational iOS app designed to help young students (ages 5-9) prepare for the Thailand International Mathematical Olympiad (TIMO) Primary 1 exam. It provides an adaptive, personalized learning experience through AI-driven question selection, performance tracking, and difficulty adjustment.

### **2. Objectives & Goals**
- Provide an **AI-powered adaptive learning experience** tailored to individual students.
- Implement **personalized question selection** using ML techniques (Collaborative Filtering, Decision Trees, and Reinforcement Learning).
- Ensure **adaptive difficulty adjustment** via Elo Rating, Bayesian Knowledge Tracing (BKT), and Item Response Theory (IRT).
- Support **multiple-choice and open-ended questions**, with NLP processing for evaluation.
- Enable **real-time performance tracking** and **AI-generated reports**.

---

## **3. Features & Requirements**

### **3.1 Exam Format Alignment**
- **Subjects Covered**:
  - Logical Thinking
  - Arithmetic
  - Number Theory
  - Geometry
  - Combinatorics
- **Question Types**:
  - Multiple-choice questions with pre-defined options.
  - Open-ended questions requiring NLP processing.
- **Structured Difficulty Levels**:
  - Easy
  - Medium
  - Hard
  - Olympiad Level
- **Progress Tracking**:
  - Track performance per subject and question type.

### **3.2 AI-Driven Lesson Selection**
- **AI Recommendation System**:
  - **Collaborative Filtering**: Identifies similar learning patterns.
  - **Decision Trees & Reinforcement Learning**: Adjusts learning paths dynamically.
  - **NLP Processing** for open-ended responses.
  - **Computer Vision (optional)** for recognizing handwritten responses in Geometry.
- **Personalized Recommendations**:
  - AI-driven question selection based on past performance.
  - Instant feedback on responses.

### **3.3 Adaptive Difficulty Algorithm**
- **Elo Rating System**:
  - Adjusts difficulty based on correctness and confidence.
  - Ensures gradual skill progression.
- **Bayesian Knowledge Tracing (BKT)**:
  - Predicts student proficiency and suggests next steps.
- **Item Response Theory (IRT)**:
  - Assigns difficulty values based on student responses.
- **Personalized Progression**:
  - Adjusts learning paths dynamically.

### **3.4 AI Model Training**
- **Training Data**:
  - TIMO sample questions.
  - Synthetic data to improve AI accuracy.
- **Feedback Loop**:
  - Reinforcement learning for incorrect answers.
  - AI error analysis for structured learning improvements.

### **3.5 Technical Implementation**
- **Modular Architecture**:
  - `SwiftUI` for UI/UX (interactive questions, progress visualization).
  - `CoreML` for on-device AI inference.
  - `CloudKit` for syncing progress across devices.
  - Custom Swift algorithms for adaptive learning logic.
- **Interactive UI Components**:
  - Drag-and-drop answers for combinatorics.
  - Dynamic geometry shapes visualization.
- **Performance Optimization**:
  - SwiftUI animations for engagement.
  - Background processing for AI model inference.

### **3.6 Evaluation Metrics**
- **Accuracy Tracking**:
  - Performance percentages per subject and difficulty level.
- **Response Time Analysis**:
  - Measures student confidence levels.
- **AI-Generated Reports**:
  - Strengths, weaknesses, and personalized recommendations.

---

## **4. System Architecture**
### **4.1 Folder Structure**
```
AITimoMath/
│── Models/                     # Data models for AI, questions, student progress
│── Views/                      # SwiftUI UI components
│── ViewModels/                 # Business logic and AI integration
│── Services/                   # AI processing, NLP, Adaptive Difficulty algorithms
│── Data/                       # Preloaded TIMO question bank
│── AI/                         # CoreML models, Reinforcement Learning logic
│── Utils/                      # Helper functions, extensions
│── Resources/                  # Assets, exam screenshots
```

### **4.2 Core Components**
- **`Models/Question.swift`**: Defines question structure.
- **`Services/AILessonSelector.swift`**: AI-based question selection.
- **`Services/AdaptiveEngine.swift`**: Adaptive difficulty logic.
- **`AI/TrainModel.swift`**: AI model training and learning reinforcement.
- **`Views/QuestionCardView.swift`**: Displays interactive questions.
- **`Services/Analytics.swift`**: Tracks student progress and generates reports.

---

## **5. Milestones & Roadmap**
### **Phase 1: MVP Development (Weeks 1-3)**
- ✅ Define folder structure and implement question bank.
- ✅ Develop AI-driven lesson selection logic.
- ✅ Implement adaptive difficulty algorithms.

### **Phase 2: AI Training & Testing (Weeks 4-6)**
- ✅ Train AI models with sample TIMO questions.
- ✅ Implement reinforcement learning feedback loop.
- ✅ Test AI-based question selection and response evaluation.

### **Phase 3: UI/UX & Optimization (Weeks 7-8)**
- ✅ Implement interactive SwiftUI components.
- ✅ Optimize AI processing for on-device inference.
- ✅ Conduct beta testing with students and refine AI recommendations.

### **Phase 4: Launch & Performance Tracking (Weeks 9-10)**
- ✅ Final AI model tuning and deployment.
- ✅ Release v1.0 with full feature set.
- ✅ Implement post-launch analytics and improvements.

---

## **6. Success Criteria**
- **Technical Completeness**:
  - All core features (adaptive difficulty, AI-driven selection, NLP processing) work as expected.
- **User Engagement**:
  - Students actively complete lessons and improve scores over time.
- **Accuracy & Performance**:
  - AI recommendations align with student learning needs.
  - Progress tracking provides valuable insights to parents & educators.

---

## **7. Risks & Mitigation**
| **Risk** | **Mitigation Strategy** |
|----------------|-----------------------------|
| AI model bias | Train with diverse sample sets & validate recommendations. |
| Performance issues | Optimize AI inference & background processing. |
| User disengagement | Add engaging UI elements & gamified progression. |
| Incorrect AI recommendations | Implement real-time feedback and improvement loops. |

---

## **8. Conclusion**
This **Adaptive Learning Engine for TIMO Math Lessons** aims to revolutionize how young students engage with mathematical problem-solving. By leveraging **AI-powered question selection, adaptive difficulty adjustment, and real-time progress tracking**, it creates a **personalized and engaging learning experience** for students preparing for the TIMO competition. 🚀

