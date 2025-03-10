# **ML Training for Adaptive Learning Engine (TIMO Math Lessons)**

## **1️⃣ Overview**
📌 **Purpose:** This document outlines the **AI model training process**, including dataset preparation, training techniques, and reinforcement learning feedback mechanisms for improving personalized lesson recommendations.

✅ **Key Components:**
- Dataset Preparation & Preprocessing
- AI Model Training Techniques
- Reinforcement Learning & Feedback Loops
- Performance Evaluation & Optimization

---

## **2️⃣ Dataset Preparation**
📌 **Goal:** Collect and preprocess math problems to train AI for **adaptive difficulty selection and student learning progression.**

### **2.1 Data Sources**
✅ **Primary Data:**
- TIMO (Thailand International Mathematical Olympiad) **sample exam questions**.
- Categorized by subject: **Logical Thinking, Arithmetic, Number Theory, Geometry, Combinatorics**.
- Labeled with **difficulty levels** (Easy, Medium, Hard, Olympiad).

✅ **Synthetic Data Generation:**
- AI-generated **variations of TIMO questions** for increased model robustness.
- Reinforcement learning-based **misconception-driven question modifications**.

✅ **Student Performance Data:**
- Accuracy per question type and difficulty.
- Response time trends.
- Common incorrect answer patterns.

### **2.2 Data Preprocessing**
✅ **Cleaning & Formatting:**
- Convert math questions into structured JSON format.
- Tokenize open-ended responses for NLP analysis.
- Remove duplicate or biased questions.

✅ **Feature Engineering:**
- **Student Skill Vectors** → Performance history-based profiling.
- **Difficulty Metrics** → Adjusted using **Item Response Theory (IRT)**.
- **Response Time Analysis** → Determines confidence & engagement.

---

## **3️⃣ AI Model Training Techniques**
📌 **Goal:** Train AI to dynamically adjust difficulty based on user performance.

### **3.1 Training Models Used**
| **Model** | **Purpose** |
|-----------|------------|
| **Elo Rating System** | Adjusts difficulty for next session based on accuracy. |
| **Bayesian Knowledge Tracing (BKT)** | Predicts concept mastery over time. |
| **Item Response Theory (IRT)** | Maps question difficulty to student ability. |
| **Collaborative Filtering** | Recommends personalized lessons based on similar students. |

### **3.2 Training Process**
✅ **Step 1: Data Splitting**
- **80% training, 10% validation, 10% testing**.

✅ **Step 2: Model Training**
- Train **Elo, BKT, and IRT models** on historical student performance.
- Fine-tune hyperparameters for **optimal difficulty adjustments**.

✅ **Step 3: Evaluation**
- AI tests on **new student responses** to verify difficulty predictions.

✅ **Step 4: Deployment & Continuous Learning**
- Deploy **trained models via CoreML** for on-device inference.
- Implement **real-time updates based on new user data**.

---

## **4️⃣ Reinforcement Learning & Feedback Mechanism**
📌 **Goal:** Improve AI recommendations through continuous learning.

### **4.1 AI Feedback Loop**
1️⃣ **Student completes a lesson** → AI records accuracy & response time.
2️⃣ **AI evaluates weak areas** → Identifies common mistakes.
3️⃣ **Difficulty is adjusted for the next session** (not mid-session).
4️⃣ **New personalized lesson generated** based on updated student model.

✅ **Example Feedback Logic:**
- **High accuracy & fast response → Increase difficulty next session.**
- **Struggles with specific concepts → Reinforce similar questions.**
- **Long response time but correct → AI adjusts pacing rather than difficulty.**

### **4.2 Adaptive Learning Improvements**
- **AI tracks student growth** over weeks/months.
- **Reinforcement model rewards correct conceptual mastery**.
- **AI continuously refines difficulty predictions** based on **real-world usage**.

---

## **5️⃣ Performance Evaluation & Optimization**
📌 **Goal:** Ensure AI provides accurate, effective difficulty adjustments.

### **5.1 Evaluation Metrics**
| **Metric** | **Purpose** |
|------------|------------|
| **Accuracy Score** | Measures correctness at each difficulty level. |
| **Prediction Precision** | AI's ability to assign correct difficulty. |
| **Response Time Trends** | Evaluates engagement & pacing. |
| **Student Retention Rate** | Tracks effectiveness of adaptive learning. |

### **5.2 Model Optimization Strategies**
✅ **Hyperparameter Tuning** → Adjust learning rates in BKT & IRT models.  
✅ **Bias Reduction** → Ensure difficulty progression is gradual & fair.  
✅ **Continuous Dataset Expansion** → Improve AI accuracy over time.  

---

## **6️⃣ Next Steps & Future Enhancements**
✅ **Refine reinforcement learning mechanisms** based on real student data.
✅ **Expand dataset to include more TIMO-style problems.**
✅ **Optimize AI latency for real-time on-device lesson selection.**

📌 **Next Steps:** Final model testing, deployment optimization, and student engagement tracking. 🚀

