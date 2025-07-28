import Foundation

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    private init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    var displayName: String {
        userName.isEmpty ? "Your" : userName + "'s"
    }
    
    func completeOnboarding(with name: String) {
        userName = name
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        userName = ""
        hasCompletedOnboarding = false
    }
}