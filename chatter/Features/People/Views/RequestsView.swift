//
//  RequestsView.swift
//  chatter
//

import SwiftUI

struct RequestsView: View {
    @ObservedObject var viewModel: PeopleViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoadingRequests && viewModel.receivedRequests.isEmpty && viewModel.sentRequests.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            UserSkeletonView()
                        }
                    }
                    .padding(.top, 12)
                }
            } else if viewModel.receivedRequests.isEmpty && viewModel.sentRequests.isEmpty {
                EmptyStateView(
                    icon: "envelope.open",
                    title: "No Pending Requests",
                    description: "You have no incoming or outgoing friend requests at this time."
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Received Requests Section
                        if !viewModel.receivedRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Received Requests (\(viewModel.receivedRequests.count))")
                                        .font(.chatterHeadline)
                                        .foregroundColor(.chatterText)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                
                                ForEach(viewModel.receivedRequests) { req in
                                    UserRowView(user: req.sender) {
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                Task {
                                                    await viewModel.acceptRequest(req)
                                                }
                                            }) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .frame(width: 32, height: 32)
                                                    .background(Color.chatterGradient)
                                                    .clipShape(Circle())
                                            }
                                            
                                            Button(action: {
                                                Task {
                                                    await viewModel.declineRequest(req)
                                                }
                                            }) {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.chatterSubtext)
                                                    .frame(width: 32, height: 32)
                                                    .background(Color.chatterInputBackground)
                                                    .clipShape(Circle())
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        
                        // Sent Requests Section
                        if !viewModel.sentRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Sent Requests (\(viewModel.sentRequests.count))")
                                        .font(.chatterHeadline)
                                        .foregroundColor(.chatterText)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                
                                ForEach(viewModel.sentRequests) { req in
                                    UserRowView(user: req.receiver) {
                                        Button(action: {
                                            Task {
                                                await viewModel.cancelRequest(req)
                                            }
                                        }) {
                                            Text("Cancel")
                                                .font(.chatterCaptionBold)
                                                .foregroundColor(.chatterSubtext)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.chatterInputBackground)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .refreshable {
            await viewModel.fetchRequests()
        }
    }
}
