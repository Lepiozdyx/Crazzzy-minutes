import SwiftUI

extension View {
    func bg() -> some View {
        self.background(Color(red: 0.89, green: 0.77, blue: 0.62).ignoresSafeArea())
    }
}

