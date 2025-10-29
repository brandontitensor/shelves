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

    @Published var bookplateStyle: BookplateStyle {
        didSet {
            UserDefaults.standard.set(bookplateStyle.rawValue, forKey: "bookplateStyle")
        }
    }

    private init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        // Load bookplate style from UserDefaults
        if let savedStyle = UserDefaults.standard.string(forKey: "bookplateStyle"),
           let style = BookplateStyle(rawValue: savedStyle) {
            self.bookplateStyle = style
        } else {
            self.bookplateStyle = .classic
        }
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