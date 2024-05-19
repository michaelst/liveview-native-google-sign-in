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
    @Event("onSignIn", type: "click") private var onSignIn
    
    var body: some View {
        GoogleSignInSwift.GoogleSignInButton(action: handleSignInButton)
            .onAppear {
                GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                    guard error == nil else { return }
                    
                    guard let user = user else { return }
                    guard let idToken = user.idToken else { return }
                    
                    onSignIn(value: ["id_token": idToken.tokenString])
                }
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
