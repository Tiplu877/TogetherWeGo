//
//  AuthView.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/2/26.
//


import SwiftUI

struct AuthView: View {
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        @Bindable var auth = auth

        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $auth.mode) {
                        Text("Sign In").tag(AuthViewModel.Mode.signIn)
                        Text("Create Account").tag(AuthViewModel.Mode.signUp)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    if auth.mode == .signUp {
                        TextField("Your name", text: $auth.name)
                            .textContentType(.name)
                    }
                    TextField("Email", text: $auth.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $auth.password)
                    if auth.mode == .signUp {
                        SecureField("Confirm password", text: $auth.confirmPassword)
                    }
                }

                if let message = auth.errorMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await auth.submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if auth.isLoading {
                                ProgressView()
                            } else {
                                Text(auth.mode == .signUp ? "Create Account" : "Sign In")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(auth.isLoading)
                }
            }
            .navigationTitle("TogetherWeGo")
            .onChange(of: auth.mode) {
                auth.errorMessage = nil
            }
        }
    }
}

#Preview {
    AuthView()
        .environment(AuthViewModel(loadCurrentUser: false))
}