//
//  RequestsView.swift
//  chatter
//

import SwiftUI

struct RequestsView: View {
    @ObservedObject var viewModel: PeopleViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Filter: Friend Requests vs Sent Requests
            HStack(spacing: 8) {
                filterButton(title: "Friend Requests", count: viewModel.receivedRequests.count, filter: .received)
                filterButton(title: "Sent Requests", count: viewModel.sentRequests.count, filter: .sent)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            // Content according to selected filter
            Group {
                switch viewModel.requestFilter {
                case .received:
                    receivedRequestsContent
                case .sent:
                    sentRequestsContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .refreshable {
            await viewModel.fetchRequests()
        }
    }
    
    // MARK: - Filter Button
    private func filterButton(title: String, count: Int, filter: RequestFilter) -> some View {
        let isSelected = viewModel.requestFilter == filter
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.requestFilter = filter
            }
        }) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.chatterSubheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? .white : .chatterSubtext)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.25) : Color.chatterInputBackground)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : .chatterText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        Color.chatterGradient
                    } else {
                        Color.chatterCardBackground
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: isSelected ? Color.chatterPrimary.opacity(0.25) : Color.clear, radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Received Requests Content
    @ViewBuilder
    private var receivedRequestsContent: some View {
        if viewModel.isLoadingRequests && viewModel.receivedRequests.isEmpty {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        UserSkeletonView()
                    }
                }
                .padding(.top, 12)
            }
        } else if viewModel.receivedRequests.isEmpty {
            EmptyStateView(
                icon: "envelope.open",
                title: "No Friend Requests",
                description: "You have no incoming friend requests at this time."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
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
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Sent Requests Content
    @ViewBuilder
    private var sentRequestsContent: some View {
        if viewModel.isLoadingRequests && viewModel.sentRequests.isEmpty {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        UserSkeletonView()
                    }
                }
                .padding(.top, 12)
            }
        } else if viewModel.sentRequests.isEmpty {
            EmptyStateView(
                icon: "paperplane",
                title: "No Sent Requests",
                description: "You have not sent any pending friend requests."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
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
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview("Requests View") {
    let vm = PeopleViewModel()
    vm.receivedRequests = [FriendRequest.mockList[0], FriendRequest.mockList[1]]
    vm.sentRequests = [FriendRequest.mockList[2]]
    return RequestsView(viewModel: vm)
        .background(Color.chatterBackground)
}
