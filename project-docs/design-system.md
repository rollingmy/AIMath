# **Design System for Adaptive Learning Engine (TIMO Math Lessons)**

## **1️⃣ Overview**
📌 **Purpose:** Define the UI components, typography, colors, and interaction elements for a **consistent and user-friendly experience** across the Adaptive Learning Engine.

✅ **Key Design Areas:**
- Typography & Color Palette
- UI Components (Buttons, Cards, Inputs)
- Icons & Illustrations
- Layout Guidelines

---

## **2️⃣ Typography**
📌 **Goal:** Ensure readability and accessibility for young learners.

| **Text Type**   | **Font**          | **Size** | **Weight** | **Usage** |
|---------------|----------------|--------|--------|----------|
| Headings (H1) | SF Pro Rounded | 28px   | Bold   | Section Titles |
| Subheadings (H2) | SF Pro Rounded | 24px   | Medium | Dashboard Headers |
| Body Text     | SF Pro          | 18px   | Regular | General Text |
| Button Text   | SF Pro Rounded | 20px   | Semi-Bold | Call-to-action buttons |
| Small Labels  | SF Pro          | 14px   | Medium | Tooltips, Captions |

✅ **Accessibility:** Ensure **high contrast** and adequate size for young learners.

---

## **3️⃣ Color Palette**
📌 **Goal:** Use **engaging, vibrant colors** suitable for children while maintaining clarity.

| **Color** | **Hex Code** | **Usage** |
|----------|------------|----------|
| 🎨 **Primary Blue** | `#2F80ED` | Buttons, Links |
| 🎨 **Secondary Yellow** | `#F2C94C` | Highlights, Active States |
| 🎨 **Success Green** | `#27AE60` | Correct Answers, Positive Feedback |
| 🎨 **Error Red** | `#EB5757` | Incorrect Answers, Warnings |
| 🎨 **Background Light** | `#F7F9FC` | General App Background |
| 🎨 **Dark Gray** | `#333333` | Text, Icons |

✅ **Contrast & Accessibility:** Ensure all UI elements pass **WCAG 2.1 AA contrast ratios**.

---

## **4️⃣ UI Components**
📌 **Goal:** Define **reusable components** for a cohesive user experience.

### **4.1 Buttons**
✅ **Primary Button:** Large, rounded corners, high contrast.
```swift
Button(action: { }) {
    Text("Start Lesson")
        .font(.system(size: 20, weight: .semibold))
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
}
```
✅ **Variants:**
- **Primary (Blue)** → Main actions (e.g., Start Lesson, Submit Answer)
- **Secondary (Yellow)** → Supporting actions (e.g., Try Again, View Progress)
- **Disabled (Gray)** → Unavailable actions

---

### **4.2 Question & Answer Cards**
📌 **Goal:** Display math problems in an engaging, structured way.
✅ **Multiple-choice card example:**
```swift
CardView {
    VStack {
        Text("What is 3 + 2?")
            .font(.title)
            .padding()
        Button("5") { /* Correct Answer */ }
            .buttonStyle(PrimaryButtonStyle())
        Button("4") { /* Incorrect Answer */ }
            .buttonStyle(SecondaryButtonStyle())
    }
}
```
✅ **Features:**
- Large, easy-to-tap answer buttons.
- Instant feedback with **color-coded correctness**.
- Smooth transitions & animations.

---

### **4.3 Progress Bars & Indicators**
📌 **Goal:** Visually track student progress through lessons.
```swift
ProgressView(value: 0.7)
    .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
    .frame(height: 8)
    .background(Color.gray.opacity(0.3))
    .cornerRadius(4)
```
✅ **Uses:**
- **Lesson Completion Bar** → Shows progress within a lesson.
- **Daily Goal Tracker** → Displays % of completed practice.
- **Accuracy Feedback** → Visual trend of student performance.

---

### **4.4 Icons & Illustrations**
📌 **Goal:** Provide **visual clarity** and enhance engagement.
✅ **Icons Used:**
- 🏆 **Achievements** → Reward milestones
- 📊 **Progress Graph** → Performance tracking
- 🎯 **Target Icon** → Personalized AI recommendations
- ❌✅ **Correct/Incorrect Feedback** → Instant user response

✅ **Style Guide:**
- **Flat, minimal icons** for clarity.
- **Animations (SwiftUI-based)** for interactive responses.

---

## **5️⃣ Layout Guidelines**
📌 **Goal:** Maintain consistent spacing and alignment.

✅ **Margins & Padding:**
- **16px horizontal padding** on all screens.
- **8px spacing** between elements for clarity.
- **Card Components:** Rounded corners (12px) with subtle shadows.

✅ **Navigation & Page Structure:**
- **Main navigation at the bottom** (Dashboard, Lessons, Profile).
- **Lesson screens use full-screen modal transitions**.
- **Consistent placement of action buttons** (bottom of the screen for easy tapping).

---

## **6️⃣ Interactive Elements & Animations**
📌 **Goal:** Enhance engagement and responsiveness.
✅ **Animations Used:**
- **Correct Answer Feedback:** Green glow effect with bounce animation.
- **Lesson Completion:** Confetti effect when achieving milestones.
- **Button Press Effects:** Subtle scaling on press for tactile feedback.

✅ **SwiftUI Example:**
```swift
withAnimation(.spring()) {
    isCorrect.toggle()
}
```

---

## **🚀 Final Thoughts**
This **design system** ensures:
✅ **A visually appealing and child-friendly UI.**
✅ **Consistent, reusable components for a smooth user experience.**
✅ **Strong accessibility and usability principles.**
✅ **Scalability for future feature expansions.**

