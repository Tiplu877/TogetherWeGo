//
//  AuthViewModel.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/2/26.
//


import Foundation
import Observation
import FirebaseAuth

@Observable
class AuthViewModel {
    enum Mode { case signIn, signUp }

    // Who is signed in (nil = nobody)
    var userID: String?
    var displayName = ""

    // Form fields
    var mode: Mode = .signIn
    var name = ""
    var email = ""
    var password = ""
    var confirmPassword = ""

    var errorMessage: String?
    var isLoading = false

    var isSignedIn: Bool { userID != nil }

    init(loadCurrentUser: Bool = true) {
        // If someone signed in before, Firebase remembers them
        if loadCurrentUser, let user = Auth.auth().currentUser {
            userID = user.uid
            displayName = user.displayName ?? ""
        }
    }

    // MARK: - Validation

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private func isValidEmail(_ text: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private func validationError() -> String? {
        if mode == .signUp && trimmedName.isEmpty { return "Enter your name so your group knows who you are." }
        if !isValidEmail(trimmedEmail) { return "Enter a valid email, like sam@example.com." }
        if password.isEmpty { return "Enter your password." }
        if mode == .signUp && password.count < 8 { return "Password must be at least 8 characters." }
        if mode == .signUp && password != confirmPassword { return "Passwords don't match." }
        return nil
    }

    // MARK: - Actions

    func submit() async {
        errorMessage = validationError()
        guard errorMessage == nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            if mode == .signUp {
                let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
                let change = result.user.createProfileChangeRequest()
                change.displayName = trimmedName
                try await change.commitChanges()
                displayName = trimmedName
                userID = result.user.uid
            } else {
                let result = try await Auth.auth().signIn(withEmail: trimmedEmail, password: password)
                displayName = result.user.displayName ?? ""
                userID = result.user.uid
            }
            password = ""
            confirmPassword = ""
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            userID = nil
            displayName = ""
        } catch {
            errorMessage = "Couldn't sign out. Try again."
        }
    }

    // Turns Firebase's technical errors into plain English
    private func friendlyMessage(for error: Error) -> String {
        switch AuthErrorCode(rawValue: (error as NSError).code) {
        case .emailAlreadyInUse: return "An account with this email already exists. Try signing in."
        case .invalidEmail: return "That email address isn't valid."
        case .weakPassword: return "Choose a stronger password."
        case .wrongPassword, .userNotFound, .invalidCredential: return "Email or password is incorrect."
        case .networkError: return "No internet connection. Check it and try again."
        case .tooManyRequests: return "Too many attempts. Wait a minute and try again."
        default: return "Something went wrong. Please try again."
        }
    }
}