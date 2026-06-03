//
//  ContentView.swift
//  MagicMouseZoomBridge
//
//  Created by Enes Akkus on 4.06.2026.
//  Copyright © 2026 Enes Akkus. All rights reserved.
//

//
//  ContentView.swift
//  MagicMouseZoomBridge
//
//  Created by Enes Akkuş on 3.06.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "plus.magnifyingglass")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Magic Mouse Zoom Bridge is running from the menu bar.")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
