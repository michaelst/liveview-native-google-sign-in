//
//  File.swift
//
//
//  Created by Michael St Clair on 5/16/24.
//

import SwiftUI
import LiveViewNative
import GoogleSignInSwift
import GoogleSignIn

@_documentation(visibility: public)
@LiveElement
struct GoogleSignInButton<Root: RootRegistry>: View {
    private var user_state = ""
    @Event("onSignIn", type: "click") private var onSignIn
    
    @ViewBuilder
    var body: some View {
        if user_state == "not_logged_in" {
            GoogleSignInSwift.GoogleSignInButton(action: handleSignInButton)
        } else {
            ProgressView()
        }
        
    }
    
    func handleSignInButton() {
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {return}
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
            guard error == nil else { return }
            guard let signInResult = signInResult else { return }
            
            signInResult.user.refreshTokensIfNeeded { user, error in
                guard error == nil else { return }
                guard let user = user else { return }
                
                guard let idToken = user.idToken else { return }
                
                onSignIn(value: ["id_token": idToken.tokenString])
            }
        }
        
    }
}
