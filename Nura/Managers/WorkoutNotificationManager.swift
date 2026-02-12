import Foundation
import HealthKit
import UserNotifications

/// Listens for workouts from Apple Watch / Fitness (HealthKit) and sends a congratulatory
/// notification prompting the user to scan their face for skin insights.
final class WorkoutNotificationManager: ObservableObject {
    static let shared = WorkoutNotificationManager()
    
    private let healthStore = HKHealthStore()
    private let userDefaults = UserDefaults.standard
    private let lastNotifiedWorkoutKey = "nura_last_notified_workout_uuid"
    private let workoutNotificationsEnabledKey = "nura_workout_notifications_enabled"
    
    /// HealthKit is only available on a real device (not Simulator).
    var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    
    @Published private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published private(set) var isObservingWorkouts = false
    
    private init() {
        if isHealthDataAvailable {
            authorizationStatus = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        }
    }
    
    var workoutNotificationsEnabled: Bool {
        get { userDefaults.bool(forKey: workoutNotificationsEnabledKey) }
        set {
            userDefaults.set(newValue, forKey: workoutNotificationsEnabledKey)
            if newValue {
                startObservingWorkoutsIfAuthorized()
            } else {
                stopObservingWorkouts()
            }
        }
    }
    
    // MARK: - Authorization
    
    /// Request read-only access to workout data. Call once when the user enables workout notifications.
    func requestAuthorization() async -> Bool {
        guard isHealthDataAvailable else {
            print("🏃 WorkoutNotificationManager: HealthKit not available (e.g. Simulator)")
            return false
        }
        
        let workoutType = HKObjectType.workoutType()
        let typesToRead: Set<HKObjectType> = [workoutType]
        
        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: typesToRead) { [weak self] _, error in
                if let error = error {
                    print("❌ WorkoutNotificationManager: Authorization failed: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                    return
                }
                let status = self?.healthStore.authorizationStatus(for: workoutType) ?? .notDetermined
                DispatchQueue.main.async {
                    self?.authorizationStatus = status
                    print("🏃 WorkoutNotificationManager: Authorization result: \(status.rawValue)")
                    if status == .sharingAuthorized {
                        self?.startObservingWorkoutsIfAuthorized()
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    // MARK: - Observer
    
    func startObservingWorkoutsIfAuthorized() {
        guard isHealthDataAvailable else { return }
        guard workoutNotificationsEnabled else { return }
        guard healthStore.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized else { return }
        
        let workoutType = HKObjectType.workoutType()
        
        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("❌ WorkoutNotificationManager: Observer error: \(error.localizedDescription)")
                return
            }
            self?.handleNewWorkoutData()
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
            if let error = error {
                print("❌ WorkoutNotificationManager: Background delivery error: \(error.localizedDescription)")
            } else {
                print("🏃 WorkoutNotificationManager: Background delivery enabled: \(success)")
            }
        }
        
        isObservingWorkouts = true
        print("🏃 WorkoutNotificationManager: Started observing workouts")
        
        // Also check for any recent workout we might have missed (e.g. app was killed)
        handleNewWorkoutData()
    }
    
    func stopObservingWorkouts() {
        isObservingWorkouts = false
        print("🏃 WorkoutNotificationManager: Stopped observing workouts")
    }
    
    private func handleNewWorkoutData() {
        guard workoutNotificationsEnabled else { return }
        guard LocalNotificationService.shared.isAuthorized else { return }
        
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: nil,
            limit: 1,
            sortDescriptors: [sort]
        ) { [weak self] _, samples, error in
            guard let self = self else { return }
            if let error = error {
                print("❌ WorkoutNotificationManager: Query error: \(error.localizedDescription)")
                return
            }
            guard let workout = samples?.first as? HKWorkout else { return }
            
            let workoutId = workout.uuid.uuidString
            let endDate = workout.endDate
            let lastNotified = self.userDefaults.string(forKey: self.lastNotifiedWorkoutKey)
            
            // Only notify if this is a new workout we haven't notified for
            guard workoutId != lastNotified else { return }
            
            // Only notify for workouts that ended in the last 30 minutes (avoid old data)
            let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
            guard endDate >= thirtyMinutesAgo else { return }
            
            DispatchQueue.main.async {
                self.userDefaults.set(workoutId, forKey: self.lastNotifiedWorkoutKey)
                self.sendWorkoutCongratsNotification()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func sendWorkoutCongratsNotification() {
        LocalNotificationService.shared.sendWorkoutCongratsNotification()
    }
}
