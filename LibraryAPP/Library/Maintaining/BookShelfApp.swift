// MARK: - BookShelfApp.swift
// App entry point

import SwiftUI

@main
struct BookShelfApp: App {
    @StateObject private var favourites = FavouritesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favourites)
        }
    }
}

// MARK: - ContentView (Tab Root)
struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Discover", systemImage: "books.vertical.fill")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            FavouritesView()
                .tabItem {
                    Label("Library", systemImage: "heart.fill")
                }
        }
        .accentColor(Color("AccentOrange"))
        .preferredColorScheme(.dark)
    }
}
