import SwiftUI
import SwiftData

struct CrazzzyAppView: View {
    var body: some View {
        TabBarView()
            .preferredColorScheme(.light)
            .modelContainer(for: [
                CategoryModel.self,
                AnimalModel.self,
                AviaryModel.self
            ])
    }
}
