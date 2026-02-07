// MARK: - SettingsView.swift
// VinCircle - iOS Social Wine App
// App settings with wine-red theme

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var friendActivityEnabled = true
    @State private var newWineAlerts = false
    @State private var showingSignOut = false
    @State private var showingDeleteAccount = false
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section {
                    NavigationLink {
                        AccountSettingsView()
                    } label: {
                        SettingsRow(icon: "person.circle.fill", title: "Account", color: Color.wineRed)
                    }
                    
                    NavigationLink {
                        AuthenticationSettingsView()
                    } label: {
                        SettingsRow(icon: "key.fill", title: "Sign-in & Security", color: Color.champagneGold)
                    }
                } header: {
                    Text("Account")
                }
                
                // Notifications Section
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        SettingsRow(icon: "bell.fill", title: "Push Notifications", color: Color.wineRed)
                    }
                    .tint(Color.wineRed)
                    
                    Toggle(isOn: $friendActivityEnabled) {
                        SettingsRow(icon: "person.2.fill", title: "Friend Activity", color: .roseGold)
                    }
                    .tint(Color.wineRed)
                    .disabled(!notificationsEnabled)
                    
                    Toggle(isOn: $newWineAlerts) {
                        SettingsRow(icon: "wineglass.fill", title: "New Wine Alerts", color: Color.champagneGold)
                    }
                    .tint(Color.wineRed)
                    .disabled(!notificationsEnabled)
                } header: {
                    Text("Notifications")
                }
                
                // Privacy Section
                Section {
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        SettingsRow(icon: "hand.raised.fill", title: "Privacy", color: .deepBurgundy)
                    }
                    
                    NavigationLink {
                        Text("Data & Storage Settings")
                    } label: {
                        SettingsRow(icon: "externaldrive.fill", title: "Data & Storage", color: .gray)
                    }
                } header: {
                    Text("Privacy")
                }
                
                // About Section
                Section {
                    NavigationLink {
                        Text("About VinCircle")
                    } label: {
                        SettingsRow(icon: "info.circle.fill", title: "About", color: Color.wineRed)
                    }
                    
                    Link(destination: URL(string: "https://example.com/help")!) {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .roseGold)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        SettingsRow(icon: "doc.text.fill", title: "Privacy Policy", color: .gray)
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        SettingsRow(icon: "doc.plaintext.fill", title: "Terms of Service", color: .gray)
                    }
                } header: {
                    Text("About")
                }
                
                // Sign Out Section
                Section {
                    Button {
                        showingSignOut = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundStyle(Color.wineRed)
                            Spacer()
                        }
                    }
                }
                
                // App Version
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .tint(Color.wineRed)
                }
            }
            .alert("Sign Out?", isPresented: $showingSignOut) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    // Sign out action
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(title)
        }
    }
}

// MARK: - Account Settings View

struct AccountSettingsView: View {
    @State private var displayName = "John Sommelier"
    @State private var email = "john@example.com"
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Circle()
                            .fill(WineGradients.primary)
                            .frame(width: 80, height: 80)
                            .overlay {
                                Text("JS")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: Color.wineRed.opacity(0.4), radius: 10)
                        
                        Button("Change Photo") {}
                            .font(.caption)
                            .tint(Color.wineRed)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
            Section("Profile") {
                TextField("Display Name", text: $displayName)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
            }
            
            Section {
                Button("Delete Account", role: .destructive) {}
            }
        }
        .navigationTitle("Account")
    }
}

// MARK: - Authentication Settings View

struct AuthenticationSettingsView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "apple.logo")
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Sign in with Apple")
                            .font(.subheadline.bold())
                        Text("Connected")
                            .font(.caption)
                            .foregroundStyle(Color.champagneGold)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.champagneGold)
                }
            } header: {
                Text("Connected Accounts")
            }
            
            Section {
                Button {
                    // Set up passkey
                } label: {
                    HStack {
                        Image(systemName: "key.fill")
                            .font(.title2)
                            .foregroundStyle(Color.wineRed)
                        VStack(alignment: .leading) {
                            Text("Set Up Passkey")
                                .font(.subheadline.bold())
                            Text("Use Face ID or Touch ID to sign in")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Passkey Authentication")
            } footer: {
                Text("Passkeys provide a more secure and convenient way to sign in. They work across all your Apple devices.")
            }
            
            Section {
                NavigationLink {
                    Text("Active Sessions")
                } label: {
                    Label("Active Sessions", systemImage: "iphone")
                }
            }
        }
        .navigationTitle("Sign-in & Security")
    }
}

// MARK: - Privacy Settings View

struct PrivacySettingsView: View {
    @State private var showInSearch = true
    @State private var shareActivity = true
    @State private var allowFriendRequests = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Show in Friend Search", isOn: $showInSearch)
                    .tint(Color.wineRed)
                Toggle("Share Activity with Friends", isOn: $shareActivity)
                    .tint(Color.wineRed)
                Toggle("Allow Friend Requests", isOn: $allowFriendRequests)
                    .tint(Color.wineRed)
            } header: {
                Text("Profile Visibility")
            }
            
            Section {
                NavigationLink {
                    Text("Blocked Users")
                } label: {
                    Text("Blocked Users")
                }
            }
            
            Section {
                Button("Download My Data") {}
                    .tint(.wineRed)
                Button("Clear Search History", role: .destructive) {}
            }
        }
        .navigationTitle("Privacy")
    }
}

#Preview {
    SettingsView()
}
