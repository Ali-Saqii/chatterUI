//
//  AuthCoordinator.swift
//  chatter
//

import SwiftUI

struct AuthCoordinator: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        NavigationStack {
            LoginView(viewModel: viewModel)
        }
    }
}

#Preview("Auth Coordinator") {
    AuthCoordinator()
        .environmentObject(AppState())
}
