import Foundation
import UserNotifications
import CoreLocation
import SwiftUI

// MARK: - Service de notifications
@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Demande d'autorisation
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("❌ Erreur demande autorisation notifications: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notifications locales
    
    /// Notification de rappel d'itinéraire
    func scheduleItineraryReminder(trip: DayTrip, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Rappel d'itinéraire"
        content.body = "Votre itinéraire '\(trip.id)' commence dans 30 minutes"
        content.sound = .default
        content.categoryIdentifier = "ITINERARY_REMINDER"
        
        let triggerDate = date.addingTimeInterval(-1800) // 30 minutes avant
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "itinerary_\(trip.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        scheduleNotification(request)
    }
    
    /// Notification de proximité pour un lieu
    func scheduleProximityNotification(for location: Location, radius: Double = 500) {
        let content = UNMutableNotificationContent()
        content.title = "Lieu à proximité"
        content.body = "Vous êtes près de \(location.name)"
        content.sound = .default
        content.categoryIdentifier = "PROXIMITY_ALERT"
        
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            radius: radius,
            identifier: "proximity_\(location.id)"
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "proximity_\(location.id)",
            content: content,
            trigger: trigger
        )
        
        scheduleNotification(request)
    }
    
    /// Notification de découverte quotidienne
    func scheduleDailyDiscovery() {
        let content = UNMutableNotificationContent()
        content.title = "Découverte du jour"
        content.body = "Découvrez de nouveaux lieux passionnants près de chez vous !"
        content.sound = .default
        content.categoryIdentifier = "DAILY_DISCOVERY"
        
        var dateComponents = DateComponents()
        dateComponents.hour = 10 // 10h du matin
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_discovery",
            content: content,
            trigger: trigger
        )
        
        scheduleNotification(request)
    }
    
    /// Notification de météo pour l'itinéraire
    func scheduleWeatherNotification(for trip: DayTrip, weatherInfo: String) {
        let content = UNMutableNotificationContent()
        content.title = "Météo pour votre itinéraire"
        content.body = weatherInfo
        content.sound = .default
        content.categoryIdentifier = "WEATHER_ALERT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // 1 heure
        
        let request = UNNotificationRequest(
            identifier: "weather_\(trip.id)",
            content: content,
            trigger: trigger
        )
        
        scheduleNotification(request)
    }
    
    /// Notification de promotion premium
    func schedulePremiumPromotion() {
        let content = UNMutableNotificationContent()
        content.title = "Débloquez tout le potentiel d'Itinerarly"
        content.body = "Passez à Premium pour des fonctionnalités exclusives !"
        content.sound = .default
        content.categoryIdentifier = "PREMIUM_PROMOTION"
        
        // Notification après 3 jours d'utilisation
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 259200, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "premium_promotion",
            content: content,
            trigger: trigger
        )
        
        scheduleNotification(request)
    }
    
    // MARK: - Gestion des notifications
    private func scheduleNotification(_ request: UNNotificationRequest) {
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Erreur planification notification: \(error)")
            } else {
                print("✅ Notification planifiée: \(request.identifier)")
            }
        }
    }
    
    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("✅ Notification annulée: \(identifier)")
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("✅ Toutes les notifications annulées")
    }
    
    func getPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests
            }
        }
    }
    
    // MARK: - Actions de notification
    func setupNotificationCategories() {
        let itineraryReminderAction = UNNotificationAction(
            identifier: "VIEW_ITINERARY",
            title: "Voir l'itinéraire",
            options: [.foreground]
        )
        
        let proximityAction = UNNotificationAction(
            identifier: "VIEW_LOCATION",
            title: "Voir le lieu",
            options: [.foreground]
        )
        
        let discoveryAction = UNNotificationAction(
            identifier: "EXPLORE",
            title: "Explorer",
            options: [.foreground]
        )
        
        let weatherAction = UNNotificationAction(
            identifier: "VIEW_WEATHER",
            title: "Voir la météo",
            options: [.foreground]
        )
        
        let premiumAction = UNNotificationAction(
            identifier: "UPGRADE_PREMIUM",
            title: "Passer à Premium",
            options: [.foreground]
        )
        
        let itineraryCategory = UNNotificationCategory(
            identifier: "ITINERARY_REMINDER",
            actions: [itineraryReminderAction],
            intentIdentifiers: [],
            options: []
        )
        
        let proximityCategory = UNNotificationCategory(
            identifier: "PROXIMITY_ALERT",
            actions: [proximityAction],
            intentIdentifiers: [],
            options: []
        )
        
        let discoveryCategory = UNNotificationCategory(
            identifier: "DAILY_DISCOVERY",
            actions: [discoveryAction],
            intentIdentifiers: [],
            options: []
        )
        
        let weatherCategory = UNNotificationCategory(
            identifier: "WEATHER_ALERT",
            actions: [weatherAction],
            intentIdentifiers: [],
            options: []
        )
        
        let premiumCategory = UNNotificationCategory(
            identifier: "PREMIUM_PROMOTION",
            actions: [premiumAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            itineraryCategory,
            proximityCategory,
            discoveryCategory,
            weatherCategory,
            premiumCategory
        ])
    }
    
    // MARK: - Notifications instantanées (pour tests)
    func sendInstantNotification(title: String, body: String, category: String = "GENERAL") {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "instant_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        scheduleNotification(request)
    }
}

// MARK: - Délégué des notifications
extension NotificationService: @preconcurrency UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Afficher la notification même si l'app est au premier plan
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.actionIdentifier
        
        switch identifier {
        case "VIEW_ITINERARY":
            // Ouvrir l'itinéraire
            handleItineraryAction(response.notification)
        case "VIEW_LOCATION":
            // Ouvrir le lieu
            handleLocationAction(response.notification)
        case "EXPLORE":
            // Ouvrir l'exploration
            handleExploreAction(response.notification)
        case "VIEW_WEATHER":
            // Ouvrir la météo
            handleWeatherAction(response.notification)
        case "UPGRADE_PREMIUM":
            // Ouvrir l'upgrade premium
            handlePremiumAction(response.notification)
        default:
            break
        }
        
        completionHandler()
    }
    
    // MARK: - Gestion des actions
    private nonisolated func handleItineraryAction(_ notification: UNNotification) {
        // Navigation vers l'itinéraire
        print("📱 Action: Voir l'itinéraire")
        // Ici vous pouvez ajouter la logique de navigation
    }
    
    private nonisolated func handleLocationAction(_ notification: UNNotification) {
        // Navigation vers le lieu
        print("📱 Action: Voir le lieu")
        // Ici vous pouvez ajouter la logique de navigation
    }
    
    private nonisolated func handleExploreAction(_ notification: UNNotification) {
        // Navigation vers l'exploration
        print("📱 Action: Explorer")
        // Ici vous pouvez ajouter la logique de navigation
    }
    
    private nonisolated func handleWeatherAction(_ notification: UNNotification) {
        // Navigation vers la météo
        print("📱 Action: Voir la météo")
        // Ici vous pouvez ajouter la logique de navigation
    }
    
    private nonisolated func handlePremiumAction(_ notification: UNNotification) {
        // Navigation vers l'upgrade premium
        print("📱 Action: Passer à Premium")
        // Ici vous pouvez ajouter la logique de navigation
    }
}

// MARK: - Extensions utiles
extension NotificationService {
    /// Vérifier si les notifications sont activées
    func areNotificationsEnabled() -> Bool {
        return isAuthorized
    }
    
    /// Obtenir le nombre de notifications en attente
    func getPendingNotificationCount() -> Int {
        return pendingNotifications.count
    }
    
    /// Supprimer les notifications expirées
    func cleanupExpiredNotifications() {
        let currentDate = Date()
        let expiredNotifications = pendingNotifications.filter { request in
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                return trigger.nextTriggerDate() ?? currentDate < currentDate
            }
            return false
        }
        
        let expiredIds = expiredNotifications.map { $0.identifier }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: expiredIds)
        
        print("🧹 \(expiredIds.count) notifications expirées supprimées")
    }
}
