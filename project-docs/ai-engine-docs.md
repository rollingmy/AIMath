# AI Engine Documentation

## Overview
The AI Engine for TIMO Math Lessons provides intelligent learning experiences through adaptive difficulty, personalized recommendations, and performance analytics.

## Core Components

### 1. PerformanceService
**Location**: `AITimoMath/Services/PerformanceService.swift`

**Purpose**: Loads and analyzes actual user performance data from lesson history.

**Key Features**:
- Loads user's completed lesson history from CloudKit
- Calculates subject-specific performance metrics
- Identifies incorrect questions for review
- Analyzes weak areas based on performance patterns

**Main Methods**:
- `loadUserLessonHistory(userId:)` - Retrieves completed lessons
- `loadIncorrectQuestions(userId:)` - Gets questions user answered incorrectly
- `calculateSubjectPerformance(userId:)` - Computes accuracy and response times per subject
- `identifyWeakAreas(userId:)` - Determines areas needing improvement

### 2. AdaptiveDifficultyEngine
**Location**: `AITimoMath/Models/AIModels/AdaptiveDifficultyEngine.swift`

**Purpose**: Dynamically adjusts question difficulty based on user performance.

**Features**:
- Real-time difficulty adjustment
- Performance-based learning paths
- Multi-algorithm approach (BKT, IRT, Elo)

### 3. AILessonSelector
**Location**: `AITimoMath/Models/AIModels/AILessonSelector.swift`

**Purpose**: Recommends optimal lessons based on user progress and performance.

**Features**:
- Personalized lesson recommendations
- Progress-based selection
- Subject balance optimization

### 4. StudentPerformanceTracker
**Location**: `AITimoMath/Models/AIModels/StudentPerformanceTracker.swift`

**Purpose**: Tracks and analyzes student performance over time.

**Features**:
- Performance trend analysis
- Learning pattern recognition
- Progress monitoring

## Data Models

### SubjectPerformanceData
```swift
public struct SubjectPerformanceData {
    public let subject: String
    public var totalQuestions: Int
    public var correctAnswers: Int
    public var accuracy: Double
    public var averageResponseTime: TimeInterval
    public var lessonsCompleted: Int
}
```

### Lesson Model
```swift
public struct Lesson: Identifiable, Codable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let subject: Subject
    public var difficulty: Int
    public var questions: [UUID]
    public var responses: [QuestionResponse]
    public var accuracy: Float
    public var responseTime: TimeInterval
    public let startedAt: Date
    public var completedAt: Date?
    public var status: LessonStatus
}
```

## Recent Improvements

### 1. Real Data Integration
- **Before**: Views showed mock/random data
- **After**: All views now display actual user performance data
- **Impact**: Users see their real progress and performance metrics

### 2. Performance Analytics
- **DashboardView**: Shows actual daily progress based on `user.dailyCompletedQuestions` vs `user.dailyGoal`
- **MistakesReviewView**: Displays questions the user actually answered incorrectly
- **PerformanceView**: Shows real accuracy trends and weak areas

### 3. Data Persistence
- All performance data is stored in CloudKit
- Lesson history is maintained for analysis
- User progress is tracked across sessions

## Usage Examples

### Loading User Performance
```swift
let performanceService = PerformanceService.shared
let subjectData = try await performanceService.calculateSubjectPerformance(userId: user.id)
let weakAreas = try await performanceService.identifyWeakAreas(userId: user.id)
```

### Getting Incorrect Questions
```swift
let incorrectQuestions = try await performanceService.loadIncorrectQuestions(userId: user.id)
```

## Integration Points

### Views Using PerformanceService
1. **DashboardView** - Shows daily progress and recommendations
2. **MistakesReviewView** - Displays questions to review
3. **PerformanceView** - Shows analytics and weak areas

### Services Integration
- **UserService** - Manages user data
- **QuestionService** - Provides question data
- **PersistenceController** - Handles CloudKit operations

## Future Enhancements

1. **Advanced Analytics**
   - Learning curve analysis
   - Time-based performance patterns
   - Subject correlation analysis

2. **Predictive Modeling**
   - Performance prediction
   - Optimal study time recommendations
   - Difficulty forecasting

3. **Personalization**
   - Learning style adaptation
   - Content recommendation engine
   - Adaptive feedback systems

