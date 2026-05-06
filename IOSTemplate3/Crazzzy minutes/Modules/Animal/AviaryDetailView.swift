import SwiftUI
import SwiftData

struct AviaryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @Bindable var aviary: AviaryModel
    
    @State private var isAddOverlayOpen = false
    @State private var nameText: String = ""
    @State private var numberText: String = ""
    
    @State private var showValidation = false
    @State private var validationMessage = ""
    
    // Детальный экран выбранного животного
    @State private var selectedAnimal: AnimalModel?
    
    // Редактирование существующего животного
    @State private var isEditOverlayOpen = false
    @State private var editTarget: AnimalModel?
    @State private var editName: String = ""
    @State private var editNumber: String = ""
    @State private var editStatus: AnimalStatus = .sale
    
    private let ratioRadius: CGFloat = 20
    
    private var sortedAnimals: [AnimalModel] {
        aviary.animals.sorted { $0.number < $1.number }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        if selectedAnimal != nil {
                            selectedAnimal = nil
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                    }
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.top, 12)
                
                Spacer().frame(height: 14)
                
                if let animal = selectedAnimal {
                    animalDetailsCard(animal)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 10)
                } else {
                    listCard
                        .padding(.horizontal, 8)
                        .padding(.bottom, 10)
                }
            }
            .bg()
            .hideKeyboardOnTap()
            .navigationBarBackButtonHidden(true)
            
            if isAddOverlayOpen {
                Color.black.opacity(0.45).ignoresSafeArea()
                addOverlay
                    .padding(.horizontal, 6)
            }
            
            if isEditOverlayOpen {
                Color.black.opacity(0.45).ignoresSafeArea()
                editOverlay
                    .padding(.horizontal, 6)
            }
        }
        .alert("Validation Error", isPresented: $showValidation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
    }
    
    // MARK: - List card
    
    private var listCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.9))
            
            VStack(spacing: 16) {
                header
                
                if sortedAnimals.isEmpty {
                    Spacer()
                    Text("No animals yet")
                    Spacer()
                } else {
                    
                    List {
                        ForEach(sortedAnimals, id: \.id) { animal in
                            residentRow(animal)
                                .listRowInsets(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedAnimal = animal
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteAnimal(animal)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
                
                HStack {
                    Spacer()
                    Button {
                        openAddOverlay()
                    } label: {
                        Text("+add a tenant")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 150, height: 42)
                            .background(Color.white)
                            .overlay(
                                Capsule()
                                    .stroke(Color(red: 0.90, green: 0.75, blue: 0.62), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(16)
        }
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            Image(aviary.animalType.asset)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
            
            Text(titleForType(aviary.animalType))
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
        }
    }
    
    private func residentRow(_ animal: AnimalModel) -> some View {
        HStack {
            Text(animal.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
            
            Text(String(format: "%04d", animal.number))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .overlay(
            Capsule()
                .stroke(Color(red: 0.90, green: 0.75, blue: 0.62), lineWidth: 1)
        )
    }
    
    // MARK: - Animal details card
    
    private func animalDetailsCard(_ animal: AnimalModel) -> some View {
        let expense = animal.expence.reduce(0, +)
        let income = animal.incomes.reduce(0, +)
        let net = income - expense
        let ratio = incomeRatio(income: income, expense: expense)
        
        return ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.9))
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(aviary.animalType.asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                    
                    Text(animal.name)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                
                statusMenu(animal)
                
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let rightW = width * ratio
                    let leftW = width - rightW
                    
                    HStack(spacing: 0) {
                        ZStack {
                            LeftRoundedRect(radius: ratioRadius)
                                .fill(Color(red: 0.70, green: 0.40, blue: 0.35))
                            if expense > 0 {
                                Text("-\(formatted(expense))")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: leftW)
                        
                        ZStack {
                            RightRoundedRect(radius: ratioRadius)
                                .fill(Color(red: 0.60, green: 0.67, blue: 0.47))
                            if income > 0 {
                                Text("+\(formatted(income))")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: rightW)
                    }
                }
                .frame(height: 86)
                .clipShape(RoundedRectangle(cornerRadius: ratioRadius, style: .continuous))
                
                Text(net >= 0 ? "+\(formatted(net))" : "\(formatted(net))")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(
                        net >= 0
                        ? Color(red: 0.60, green: 0.67, blue: 0.47)
                        : Color(red: 0.70, green: 0.40, blue: 0.35)
                    )
                    .padding(.vertical, 8)
                
                HStack(spacing: 14) {
                    Button {
                        addIncome(to: animal)
                    } label: {
                        Text("Income")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(red: 0.60, green: 0.67, blue: 0.47))
                            .clipShape(Capsule())
                    }
                    
                    Button {
                        addExpense(to: animal)
                    } label: {
                        Text("Expense")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(red: 0.70, green: 0.40, blue: 0.35))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }
    
    private func statusMenu(_ animal: AnimalModel) -> some View {
        Menu {
            ForEach(AnimalStatus.allCases, id: \.self) { status in
                Button(statusTitle(status)) {
                    animal.status = status
                    persist()
                }
            }
            
            Divider()
            
            Button("Edit", systemImage: "pencil") {
                openEditOverlay(for: animal)
            }
        } label: {
            HStack {
                Text("Status: \(statusTitle(animal.status))")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.85, green: 0.68, blue: 0.52))
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(Color.clear)
            .overlay(
                Capsule()
                    .stroke(Color(red: 0.90, green: 0.75, blue: 0.62), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Add overlay
    
    private var addOverlay: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.82, green: 0.78, blue: 0.68),
                                Color(red: 0.86, green: 0.74, blue: 0.60)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                    )
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Name")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    inputField(text: $nameText)
                    
                    Text("Number")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                    
                    inputField(text: $numberText)
                        .keyboardType(.numberPad)
                }
                .padding(18)
            }
            .frame(height: 255)
            
            Button {
                saveTenant()
            } label: {
                Text("Save")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 48)
                    .background(Color(red: 0.72, green: 0.41, blue: 0.36))
                    .clipShape(Capsule())
            }
            .padding(.top, -18)
        }
    }
    
    // MARK: - Edit overlay
    
    private var editOverlay: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.82, green: 0.78, blue: 0.68),
                                Color(red: 0.86, green: 0.74, blue: 0.60)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                    )
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Name")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    inputField(text: $editName)
                    
                    Text("Number")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                    
                    inputField(text: $editNumber)
                        .keyboardType(.numberPad)
                    
                    Text("Status")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                    
                    Picker("", selection: $editStatus) {
                        ForEach(AnimalStatus.allCases, id: \.self) { status in
                            Text(statusTitle(status)).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(18)
            }
            .frame(height: 320)
            
            Button {
                saveEditedAnimal()
            } label: {
                Text("Save")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 48)
                    .background(Color(red: 0.72, green: 0.41, blue: 0.36))
                    .clipShape(Capsule())
            }
            .padding(.top, -18)
        }
    }
    
    private func inputField(text: Binding<String>) -> some View {
        HStack {
            TextField("", text: text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.black)
            
            Image(systemName: "pencil")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.75, green: 0.84, blue: 0.90))
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    // MARK: - Actions
    
    private func openAddOverlay() {
        let nextNumber = (sortedAnimals.map(\.number).max() ?? 0) + 1
        nameText = ""
        numberText = String(nextNumber)
        isAddOverlayOpen = true
    }
    
    private func saveTenant() {
        let trimmedName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "Name cannot be empty."
            showValidation = true
            return
        }
        
        guard let number = Int(numberText), number > 0 else {
            validationMessage = "Number must be a positive integer."
            showValidation = true
            return
        }
        
        let duplicate = aviary.animals.contains { $0.number == number }
        if duplicate {
            validationMessage = "This number is already used in this aviary."
            showValidation = true
            return
        }
        
        let newAnimal = AnimalModel(
            animalType: aviary.animalType,
            status: .sale,
            name: trimmedName,
            number: number,
            incomes: [],
            expence: []
        )
        
        context.insert(newAnimal)
        aviary.animals.append(newAnimal)
        
        do {
            try context.save()
            isAddOverlayOpen = false
        } catch {
            validationMessage = "Failed to save tenant: \(error.localizedDescription)"
            showValidation = true
        }
    }
    
    private func openEditOverlay(for animal: AnimalModel) {
        editTarget = animal
        editName = animal.name
        editNumber = String(animal.number)
        editStatus = animal.status
        isEditOverlayOpen = true
    }
    
    private func saveEditedAnimal() {
        guard let target = editTarget else { return }
        
        let trimmed = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "Name cannot be empty."
            showValidation = true
            return
        }
        
        guard let number = Int(editNumber), number > 0 else {
            validationMessage = "Number must be a positive integer."
            showValidation = true
            return
        }
        
        let duplicate = aviary.animals.contains { $0.id != target.id && $0.number == number }
        if duplicate {
            validationMessage = "This number is already used in this aviary."
            showValidation = true
            return
        }
        
        target.name = trimmed
        target.number = number
        target.status = editStatus
        
        do {
            try context.save()
            isEditOverlayOpen = false
        } catch {
            validationMessage = "Failed to save changes: \(error.localizedDescription)"
            showValidation = true
        }
    }
    
    private func addIncome(to animal: AnimalModel) {
        animal.incomes.append(100)
        persist()
    }
    
    private func addExpense(to animal: AnimalModel) {
        animal.expence.append(100)
        persist()
    }
    
    private func deleteAnimal(_ animal: AnimalModel) {
        if selectedAnimal?.id == animal.id {
            selectedAnimal = nil
        }
        aviary.animals.removeAll { $0.id == animal.id }
        context.delete(animal)
        persist()
    }
    
    private func persist() {
        do {
            try context.save()
        } catch {
            validationMessage = "Save error: \(error.localizedDescription)"
            showValidation = true
        }
    }
    
    // MARK: - Helpers
    
    private func incomeRatio(income: Int, expense: Int) -> CGFloat {
        let i = CGFloat(income)
        let e = CGFloat(expense)
        let sum = i + e
        guard sum > 0 else { return 0.5 }
        if e == 0 { return 1.0 }
        if i == 0 { return 0.0 }
        return i / sum
    }
    
    private func formatted(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func statusTitle(_ status: AnimalStatus) -> String {
        switch status {
        case .sale: return "Sale"
        case .dead: return "Dead"
        case .forMeat: return "For meat"
        }
    }
    
    private func titleForType(_ type: AnimalType) -> String {
        switch type {
        case .cow: return "My Cows"
        case .chicken: return "My Chickens"
        case .hare: return "My Hares"
        case .sheep: return "My Sheep"
        }
    }
}
