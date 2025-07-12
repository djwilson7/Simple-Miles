//
//  ContentView.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/11/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    
    var body: some View {
        VStack(spacing:20) {
            Text("You're Logged In!")
                .font(.title)
            
            Button("Logout") {
                isLoggedIn = false
            }
            .foregroundColor(.red)
            .padding()
        }
        .padding()
    }
}



#Preview {
    ContentView()
}
