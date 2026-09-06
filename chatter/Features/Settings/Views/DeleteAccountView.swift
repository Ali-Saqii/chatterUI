//
//  DeleteAccountView.swift
//  chatter
//

import SwiftUI

struct DeleteAccountView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.chatterDestructive.opacity(0.12))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.chatterDestructive)
                }
                .padding(.top, 24)
                
                VStack(spacing: 8) {
                    Text("Delete Account")
                        .font(.chatterLargeTitle)
                        .foregroundColor(.chatterDestructive)
                    
                    Text("This action is permanent and cannot be undone.")
                        .font(.chatterSubheadline)
                        .foregroundColor(.chatterSubtext)
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("What will happen:")
                        .font(.chatterHeadline)
                        .foregroundColor(.chatterText)
                    
                    Label("All your posts and comments will be deleted permanently.", systemImage: "xmark.circle")
                        .font(.chatterBody)
                        .foregroundColor(.chatterSubtext)
                    
                    Label("Your friend connections and pending requests will be removed.", systemImage: "xmark.circle")
                        .font(.chatterBody)
                        .foregroundColor(.chatterSubtext)
                    
                    Label("Your username will be released for others to use.", systemImage: "xmark.circle")
                        .font(.chatterBody)
                        .foregroundColor(.chatterSubtext)
                }
                .chatterCard()
                .padding(.horizontal, 16)
                
                if let error = viewModel.deleteErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.chatterDestructive)
                        Text(error)
                            .font(.chatterCaption)
                            .foregroundColor(.chatterDestructive)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.chatterDestructive.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }
                
                PrimaryButton(
                    title: "Delete My Account",
                    icon: "trash",
                    style: .destructive,
                    isLoading: viewModel.isDeletingAccount
                ) {
                    showConfirmAlert = true
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .background(Color.chatterBackground.ignoresSafeArea())
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Are you absolutely sure?", isPresented: $showConfirmAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Forever", role: .destructive) {
                Task {
                    _ = await viewModel.deleteAccount(appState: appState)
                }
            }
        } message: {
            Text("Your account and all associated data will be permanently erased. You will not be able to recover it.")
        }
    }
}
