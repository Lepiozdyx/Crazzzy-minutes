import SwiftUI
import Observation
import SwiftData

@MainActor
@Observable
class AnimalViewModel {
    var animalType: AnimalType
    var context: ModelContext
    
    var category: CategoryModel?
    
    init(animalType: AnimalType, context: ModelContext) {
        self.animalType = animalType
        self.context = context
        ensureCategoryModel()
    }
    
    func ensureCategoryModel() {
        do {
            let descriptor = FetchDescriptor<CategoryModel>()
            let existing = try context.fetch(descriptor)
            
            if let first = existing.first {
                category = first
            } else {
                let newCategory = CategoryModel(
                    expences: [
                        .cow: [],
                        .chicken: [],
                        .hare: [],
                        .sheep: []
                    ],
                    incomes: [
                        .cow: [],
                        .chicken: [],
                        .hare: [],
                        .sheep: []
                    ]
                )
                context.insert(newCategory)
                try context.save()
                category = newCategory
            }
        } catch {
            print("Failed to ensure CategoryModel: \(error.localizedDescription)")
        }
    }
    
    var title: String {
        switch animalType {
        case .cow: return "My Cows"
        case .chicken: return "My Chickens"
        case .hare: return "My Hares"
        case .sheep: return "My Sheep"
        }
    }
    
    var incomes: [Int] { category?.incomes[animalType] ?? [] }
    var expenses: [Int] { category?.expences[animalType] ?? [] }
    
    var totalIncome: Int { incomes.reduce(0, +) }
    var totalExpense: Int { expenses.reduce(0, +) }
    var net: Int { totalIncome - totalExpense }
    
    var incomeRatio: CGFloat {
        let i = CGFloat(totalIncome)
        let e = CGFloat(totalExpense)
        let sum = i + e
        guard sum > 0 else { return 0.5 }
        return i / sum
    }
    
    func addIncome(_ value: Int = 100) {
        guard let category else { return }
        var arr = category.incomes[animalType] ?? []
        arr.append(value)
        category.incomes[animalType] = arr
        save()
    }
    
    func addExpense(_ value: Int = 100) {
        guard let category else { return }
        var arr = category.expences[animalType] ?? []
        arr.append(value)
        category.expences[animalType] = arr
        save()
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Failed to save CategoryModel: \(error.localizedDescription)")
        }
    }
}

struct AnimalView: View {
    @Bindable var viewModel: AnimalViewModel
    @Query private var aviaries: [AviaryModel]
    
    @State private var isAnimalArchiveOpen = false
    @State private var isAddAviaryOpen = false
    @State private var selectedAviary: AviaryModel?
    
    private let radius: CGFloat = 18
    
    private var currentTypeAviaries: [AviaryModel] {
        aviaries
            .filter { $0.animalType == viewModel.animalType }
            .sorted { $0.date > $1.date }
    }
    
    // Суммы из всех животных внутри aviary выбранной категории
    private var aviaryIncomeOnly: Int {
        currentTypeAviaries
            .flatMap(\.animals)
            .flatMap(\.incomes)
            .reduce(0, +)
    }
    
    private var aviaryExpenseOnly: Int {
        currentTypeAviaries
            .flatMap(\.animals)
            .flatMap(\.expence)
            .reduce(0, +)
    }
    
    // Итог = CategoryModel + AviaryModel.animals
    private var totalCombinedIncome: Int {
        viewModel.totalIncome + aviaryIncomeOnly
    }
    
    private var totalCombinedExpense: Int {
        viewModel.totalExpense + aviaryExpenseOnly
    }
    
    private var combinedNet: Int {
        totalCombinedIncome - totalCombinedExpense
    }
    
    private var combinedIncomeRatio: CGFloat {
        let i = CGFloat(totalCombinedIncome)
        let e = CGFloat(totalCombinedExpense)
        let sum = i + e
        guard sum > 0 else { return 0.5 }
        if e == 0 { return 1.0 }
        if i == 0 { return 0.0 }
        return i / sum
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isAnimalArchiveOpen = true } ) {
                        Image(.archiveBtn)
                            .resizable().scaledToFit().frame(width: 24.fitH)
                    }
                    .padding(30)
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                    
                    VStack(spacing: 16) {
                        header
                        ratioBar
                        balance
                        actions
                    }
                    .padding(16)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .padding(.horizontal, 18)
                
                VStack(spacing: 10) {
                    ForEach(currentTypeAviaries, id: \.id) { aviary in
                        aviaryRow(aviary)
                            .onTapGesture {
                                selectedAviary = aviary
                            }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                
                HStack {
                    Spacer()
                    Button {
                        isAddAviaryOpen = true
                    } label: {
                        Text("+add an aviary")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 130.fitW)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .bg()
        .hideKeyboardOnTap()
        .fullScreenCover(isPresented: $isAddAviaryOpen) {
            AddAviaryView(initialType: viewModel.animalType)
        }
        .fullScreenCover(isPresented: $isAnimalArchiveOpen) {
            AnimalArchiveView(animalType: viewModel.animalType)
        }
        .fullScreenCover(item: $selectedAviary) { aviary in
            AviaryDetailView(aviary: aviary)
        }
    }
    
    private var header: some View {
        HStack(spacing: 10) {
            Image(viewModel.animalType.asset)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
            
            Text(viewModel.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
        }
    }
    
    private var ratioBar: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let rightW = width * combinedIncomeRatio
            let leftW = width - rightW
            
            HStack(spacing: 0) {
                ZStack {
                    LeftRoundedRect(radius: radius)
                        .fill(Color(red: 0.70, green: 0.40, blue: 0.35))
                    
                    if totalCombinedExpense > 0 {
                        Text("-\(formatted(totalCombinedExpense))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.95))
                    }
                }
                .frame(width: leftW)
                
                ZStack {
                    RightRoundedRect(radius: radius)
                        .fill(Color(red: 0.60, green: 0.67, blue: 0.47))
                    
                    if totalCombinedIncome > 0 {
                        Text("+\(formatted(totalCombinedIncome))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.95))
                    }
                }
                .frame(width: rightW)
            }
        }
        .frame(height: 54)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
    
    private var balance: some View {
        Text(balanceText(combinedNet))
            .font(.system(size: 34, weight: .bold))
            .foregroundColor(
                combinedNet >= 0
                ? Color(red: 0.60, green: 0.67, blue: 0.47)
                : Color(red: 0.70, green: 0.40, blue: 0.35)
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }
    
    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.addIncome()
            } label: {
                Text("Income")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.60, green: 0.67, blue: 0.47))
                    .clipShape(Capsule())
            }
            
            Button {
                viewModel.addExpense()
            } label: {
                Text("Expense")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.70, green: 0.40, blue: 0.35))
                    .clipShape(Capsule())
            }
        }
    }
    
    private func aviaryRow(_ aviary: AviaryModel) -> some View {
        let expense = aviary.animals.flatMap(\.expence).reduce(0, +)
        let income = aviary.animals.flatMap(\.incomes).reduce(0, +)
        let net = income - expense
        
        return HStack {
            Text("\(dateString(aviary.date)) \(aviary.name)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
            
            Text(net >= 0 ? "+\(formatted(net))" : "\(formatted(net))")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(
                    net >= 0
                    ? Color(red: 0.60, green: 0.67, blue: 0.47)
                    : Color(red: 0.70, green: 0.40, blue: 0.35)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.9))
        .clipShape(Capsule())
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
    
    private func formatted(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func balanceText(_ value: Int) -> String {
        if value > 0 { return "+\(formatted(value))" }
        return "\(formatted(value))"
    }
}

// MARK: - Shapes (скругление только с одной стороны)

struct LeftRoundedRect: Shape {
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(radius, rect.height / 2, rect.width / 2)
        
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.minY))
        p.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(-180),
            clockwise: true
        )
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - r))
        p.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

struct RightRoundedRect: Shape {
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(radius, rect.height / 2, rect.width / 2)
        
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
