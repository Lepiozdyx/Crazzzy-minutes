import SwiftUI
import SwiftData

struct TabBarView: View {
    @State private var selectedTab: AppTab = .tab1
    @Environment(\.modelContext) var context
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .tab1: AnimalView(viewModel: AnimalViewModel(animalType: .cow, context: context))
                case .tab2: AnimalView(viewModel: AnimalViewModel(animalType: .chicken, context: context))
                case .tab3: AnimalView(viewModel: AnimalViewModel(animalType: .hare, context: context))
                case .tab4: AnimalView(viewModel: AnimalViewModel(animalType: .sheep, context: context))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 24.fitH)
                .padding(.bottom, 0)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

enum AppTab: Int, CaseIterable {
    case tab1
    case tab2
    case tab3
    case tab4
    
    var baseAssetName: String {
        switch self {
        case .tab1: return "tab1"
        case .tab2: return "tab2"
        case .tab3: return "tab3"
        case .tab4: return "tab4"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Image(assetName(for: tab))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 68, height: 68)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24.fitH)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white).ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func assetName(for tab: AppTab) -> String {
        let suffix = selectedTab == tab ? "-s" : "-d"
        return "\(tab.baseAssetName)\(suffix)"
    }
}
