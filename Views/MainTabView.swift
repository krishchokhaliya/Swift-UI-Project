import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            SearchBookView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Discover")
                }

            MyBooksView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("My Books")
                }

            StatisticsDashboardView()
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Insights")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
        }
        .tint(.indigo)
    }
}
