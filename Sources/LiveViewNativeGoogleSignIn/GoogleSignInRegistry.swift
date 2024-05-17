//
//  File.swift
//
//
//  Created by Michael St Clair on 5/16/24.
//

import LiveViewNative
import LiveViewNativeStylesheet
import SwiftUI

/// A registry that includes the ``Map`` element and associated modifiers.
public enum GoogleSignInRegistry<Root: RootRegistry>: CustomRegistry {
    public enum TagName: String {
        case google = "GoogleSignInButton"
    }
    
    public static func lookup(_ name: TagName, element: ElementNode) -> some View {
        switch name {
        case .google:
            SignInButton<Root>()
        }
    }
}
