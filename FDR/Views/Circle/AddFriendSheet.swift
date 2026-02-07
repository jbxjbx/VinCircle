// MARK: - AddFriendSheet.swift
// VinCircle - iOS Social Wine App
// Sheet for adding friends via OTP code or QR with wine-red theme

import SwiftUI

struct AddFriendSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasAppeared = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.wineRed)
                        .scaleEffect(hasAppeared ? 1 : 0.8)
                        .opacity(hasAppeared ? 1 : 0)
                    
                    Text("Add to Inner Circle")
                        .font(.title2.bold())
                    
                    Text("Enter your friend's 6-digit invite code")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Code Input
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ForEach(0..<6) { index in
                            CodeDigitBox(
                                digit: getDigit(at: index),
                                isActive: index == inviteCode.count
                            )
                        }
                    }
                    
                    TextField("", text: $inviteCode)
                        .keyboardType(.numberPad)
                        .opacity(0.01)
                        .frame(height: 1)
                        .onChange(of: inviteCode) { _, newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                inviteCode = String(newValue.prefix(6))
                            }
                            // Only allow numbers
                            inviteCode = newValue.filter { $0.isNumber }
                        }
                }
                
                // Or Divider
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("or")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)
                
                // QR Code Button
                Button {
                    // Scan QR action
                } label: {
                    Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.primary)
                
                Spacer()
                
                // Add Button
                Button {
                    addFriend()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Add Friend")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(inviteCode.count == 6 ? WineGradients.primary : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(inviteCode.count != 6 || isLoading)
                
                // Share Your Code
                VStack(spacing: 8) {
                    Text("Your invite code")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        // Copy code action
                        UIPasteboard.general.string = "847291"
                    } label: {
                        HStack {
                            Text("847291")
                                .font(.title3.monospaced().bold())
                                .foregroundStyle(Color.wineRed)
                            
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(Color.wineRed)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.wineRed.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(.wineRed)
                }
            }
            .alert("Friend Added!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your new friend has been added to your Inner Circle.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                withAnimation(WineAnimations.cardAppear) {
                    hasAppeared = true
                }
            }
        }
    }
    
    private func getDigit(at index: Int) -> String {
        guard index < inviteCode.count else { return "" }
        return String(inviteCode[inviteCode.index(inviteCode.startIndex, offsetBy: index)])
    }
    
    private func addFriend() {
        isLoading = true
        
        // Simulate API call
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            await MainActor.run {
                isLoading = false
                
                // Demo: specific codes show different results
                if inviteCode == "123456" {
                    showSuccess = true
                } else if inviteCode == "000000" {
                    errorMessage = "Invalid invite code. Please try again."
                    showError = true
                } else {
                    // Random success for demo
                    showSuccess = true
                }
            }
        }
    }
}

// MARK: - Code Digit Box

struct CodeDigitBox: View {
    let digit: String
    let isActive: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.wineRed : Color.gray.opacity(0.3), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
                .frame(width: 48, height: 60)
            
            Text(digit)
                .font(.title.bold())
                .foregroundStyle(Color.wineRed)
        }
    }
}

#Preview {
    AddFriendSheet()
}
