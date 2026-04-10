import SwiftUI
import SwiftData

@main
struct Crazzzy_minutesApp: App {
    var body: some Scene {
        WindowGroup {
            TabBarView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [
            CategoryModel.self,
            AnimalModel.self,
            AviaryModel.self
        ])
    }
}
