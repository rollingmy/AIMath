# **Adaptive Learning Model for TIMO Math Lessons**

## **1️⃣ Overview**
📌 **Purpose:** This document explains the **adaptive difficulty adjustment models** used in the AI-driven learning engine, ensuring that students receive personalized question difficulty based on their progress.

✅ **Models Used:**
- **Elo Rating System** → Adjusts difficulty based on performance trends.
- **Bayesian Knowledge Tracing (BKT)** → Predicts mastery of concepts.
- **Item Response Theory (IRT)** → Assigns question difficulty dynamically.

---

## **2️⃣ Elo Rating System**
📌 **Goal:** Adjust question difficulty based on **correct/incorrect answers** over time.

### **How It Works**
1️⃣ Each student starts with an **initial rating** (e.g., 1200 Elo).  
2️⃣ **Correct answer → Increases rating** → Harder questions assigned in next session.  
3️⃣ **Incorrect answer → Decreases rating** → Easier questions assigned in next session.  
4️⃣ **Difficulty is updated at the end of each lesson**, ensuring progressive learning.  

### **Formula:**
📌 **New Rating Calculation:**
```
NewRating = CurrentRating + K × (ActualScore − ExpectedScore)
```
✅ **K Factor** → Controls sensitivity to changes.  
✅ **Expected Score** → Probability of answering correctly based on difficulty gap.  

---

## **3️⃣ Bayesian Knowledge Tracing (BKT)**
📌 **Goal:** Predict whether a student has mastered a concept based on past responses.

### **How It Works**
1️⃣ Each concept starts with an **initial mastery probability (P)**.  
2️⃣ **If the student answers correctly** → P increases (suggests understanding).  
3️⃣ **If incorrect** → P decreases (concept not yet mastered).  
4️⃣ **AI uses P to decide whether to reinforce a topic in future lessons.**  

### **Formula:**
📌 **Probability of Mastery After Question:**
```
P_new = P_old + (1 - P_old) × LearningRate
```
✅ **Learning Rate** → Determines how quickly students improve mastery over time.  
✅ **Forget Rate** → Models knowledge retention (if P decays over time).  

---

## **4️⃣ Item Response Theory (IRT)**
📌 **Goal:** Assign difficulty values to questions dynamically based on student responses.

### **How It Works**
1️⃣ Each question has a **difficulty score (D)** and a **discrimination factor (a)**.  
2️⃣ AI calculates **probability of correct answer** given the student’s ability.  
3️⃣ If a student **struggles on a question**, AI reassigns a lower difficulty score for future recommendations.  
4️⃣ If the student **excels consistently**, AI selects harder problems.  

### **Formula:**
📌 **Logistic Function for Correct Answer Probability:**
```
P(Correct) = 1 / (1 + e^(-a(θ - D)))
```
✅ **θ (Theta) = Student ability level**  
✅ **D = Question difficulty level**  
✅ **a = Discrimination parameter (how well the question differentiates strong vs weak students)**  

---

## **5️⃣ Adaptive Learning Flow**
📌 **How AI decides lesson difficulty after each session.**

1️⃣ **Lesson Completed** → AI records performance data.
2️⃣ **Elo Rating Update** → Adjusts general difficulty scaling.
3️⃣ **BKT Checks Mastery** → Identifies concepts needing reinforcement.
4️⃣ **IRT Adjusts Future Questions** → Selects appropriate difficulty for next session.
5️⃣ **AI Generates Personalized Lesson Plan** → Next session adapts accordingly.

✅ **Key Rule:** **Difficulty remains static within a session but adjusts in future lessons.**

---

## **6️⃣ Next Steps & Optimization**
✅ **Fine-tune parameters for Elo, BKT, and IRT based on real student data.**
✅ **Incorporate additional metrics (response time, confidence level).**
✅ **Optimize AI feedback loops for better learning adaptation.**

📌 **Next Steps:** Test AI models with real user interactions & refine difficulty scaling for best learning outcomes. 🚀

