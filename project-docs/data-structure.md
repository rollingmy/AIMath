# **Data Structure for Adaptive Learning Engine (TIMO Math Lessons)**

## **1️⃣ Overview**
📌 **Purpose:** Define the data models, database schema, and storage methods for managing users, lessons, questions, and AI-driven learning progress.

✅ **Storage Methods:**
- **CloudKit** → Syncs user progress across devices.
- **Local Storage (Core Data / JSON)** → Supports offline learning.
- **Preloaded Question Bank (JSON/Database)** → Fast access to questions.

---

## **2️⃣ Data Model Definitions**
📌 **Core data models and attributes.**

### **2.1 User Model**
Stores student profile and learning preferences.
```json
{
  "user_id": "UUID",
  "name": "string",
  "avatar": "string",
  "grade_level": "integer",
  "learning_goal": "integer",  // Number of questions per session
  "difficulty_level": "string", // Beginner, Adaptive, Advanced
  "progress": "array"  // References to completed lessons
}
```

### **2.2 Lesson Model**
Tracks user lessons and session history.
```json
{
  "lesson_id": "UUID",
  "user_id": "UUID",
  "subject": "string",  // Logical Thinking, Arithmetic, etc.
  "questions": "array",  // List of Question IDs
  "accuracy": "float",   // Percentage score
  "response_time": "float",  // Average response time
  "completed_at": "timestamp"
}
```

### **2.3 Question Model**
Stores question data with options, correct answers, and difficulty.
```json
{
  "question_id": "UUID",
  "subject": "string",  // Logical Thinking, Arithmetic, etc.
  "difficulty": "integer", // 1 = Easy, 2 = Medium, 3 = Hard, 4 = Olympiad
  "type": "string",  // MCQ or Open-ended
  "question_text": "string",
  "options": ["string"],  // MCQ choices
  "correct_answer": "string",
  "hint": "string",  // Optional hint
  "image_url": "string"  // Optional image
}
```

### **2.4 AI Learning Progress Model**
Tracks AI-driven recommendations and progress.
```json
{
  "user_id": "UUID",
  "lesson_history": [
    {
      "lesson_id": "UUID",
      "subject": "string",
      "accuracy": "float",
      "response_time": "float",
      "next_difficulty": "integer"  // Adjusted for the next lesson
    }
  ],
  "weak_areas": ["string"],  // Topics needing improvement
  "recommended_lessons": ["UUID"]  // AI-suggested next lessons
}
```

---

## **3️⃣ Database Schema (CloudKit & Local Storage)**

### **3.1 Tables (CloudKit)**
| **Table**        | **Primary Key**  | **Description**  |
|----------------|----------------|----------------|
| Users         | user_id (UUID)  | Stores student profiles and preferences. |
| Lessons       | lesson_id (UUID) | Tracks lessons completed by students. |
| Questions     | question_id (UUID) | Stores all TIMO-based questions. |
| AI_Progress   | user_id (UUID)  | Tracks AI learning adjustments per user. |

### **3.2 Relationships**
- **Users ↔ Lessons** → One-to-Many *(Each user has multiple lessons completed.)*
- **Lessons ↔ Questions** → Many-to-Many *(Each lesson contains multiple questions.)*
- **Users ↔ AI_Progress** → One-to-One *(Each user has one AI learning progress tracker.)*

---

## **4️⃣ Data Flow & Synchronization**
📌 **How data moves across the system.**

1️⃣ **User logs in** → Fetch user profile & progress from CloudKit.  
2️⃣ **Lesson starts** → AI selects personalized questions from the database.  
3️⃣ **User submits answers** → Stores responses locally for real-time processing.  
4️⃣ **Lesson completes** → Updates accuracy, response time & AI progress.  
5️⃣ **AI recalibrates next lesson difficulty** → Syncs adjustments to CloudKit.  

---

## **5️⃣ Security & Data Integrity**
✅ **Encryption:** All user data is securely stored and transmitted.
✅ **Offline Support:** Lessons can be completed without internet access.
✅ **Data Validation:** Ensures all inputs are properly formatted and sanitized.

---

## **6️⃣ Summary & Next Steps**
✅ **Scalable data models for adaptive learning.**  
✅ **CloudKit integration for seamless progress tracking.**  
✅ **AI-powered recommendations based on real-time performance.**  

📌 **Next Steps:** Implement database queries, optimize AI learning models, and test offline syncing.


