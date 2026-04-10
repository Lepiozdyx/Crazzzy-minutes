import SwiftUI
import SwiftData

struct AnimalArchiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var animals: [AnimalModel]
    
    let animalType: AnimalType
    
    @State private var editingAnimal: AnimalModel?
    @State private var editName: String = ""
    @State private var editNumberText: String = ""
    @State private var showValidationError = false
    @State private var validationMessage = ""
    
    private var filteredAnimals: [AnimalModel] {
        animals
            .filter { $0.animalType == animalType }
            .sorted { $0.number < $1.number }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
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
                
                Spacer().frame(height: 20)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.88))
                    
                    if filteredAnimals.isEmpty {
                        VStack {
                            Spacer()
                            Text("No animals yet")
                            Spacer()
                        }
                    } else {
                        listContent
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
            .bg()
            .hideKeyboardOnTap()
            .navigationBarBackButtonHidden(true)
            
            if editingAnimal != nil {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                
                editOverlay
                    .padding(.horizontal, 12)
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(10)
            }
        }
        .alert("Validation Error", isPresented: $showValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
    }
    
    private var listContent: some View {
            List {
                ForEach(filteredAnimals, id: \.id) { animal in
                    residentRow(animal)
                        .listRowInsets(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            openEditor(for: animal)
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
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
        .padding(.horizontal, 18)
        .frame(height: 44)
        .background(Color.clear)
        .overlay(
            Capsule()
                .stroke(Color(red: 0.90, green: 0.75, blue: 0.62), lineWidth: 1)
        )
    }
    
    // MARK: - Edit Overlay
    
    private var editOverlay: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
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
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .stroke(Color.white.opacity(0.95), lineWidth: 2)
                    )
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("Name")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    inputField(text: $editName)
                    
                    Text("Number")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                    
                    inputField(text: $editNumberText)
                        .keyboardType(.numberPad)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .frame(height: 360)
            
            Button {
                saveEditedAnimal()
            } label: {
                Text("Save")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 160, height: 52)
                    .background(Color(red: 0.73, green: 0.42, blue: 0.37))
                    .clipShape(Capsule())
            }
            .padding(.top, -18)
        }
    }
    
    private func inputField(text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            TextField("", text: text)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.black)
            
            Image(systemName: "pencil")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.75, green: 0.84, blue: 0.90))
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    // MARK: - Actions
    
    private func openEditor(for animal: AnimalModel) {
        editingAnimal = animal
        editName = animal.name
        editNumberText = String(animal.number)
    }
    
    private func saveEditedAnimal() {
        guard let target = editingAnimal else { return }
        
        let trimmedName = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "Name cannot be empty."
            showValidationError = true
            return
        }
        
        guard let newNumber = Int(editNumberText), newNumber > 0 else {
            validationMessage = "Number must be a positive integer."
            showValidationError = true
            return
        }
        
        // Проверка уникальности номера в рамках категории
        let duplicateExists = animals.contains {
            $0.id != target.id &&
            $0.animalType == target.animalType &&
            $0.number == newNumber
        }
        
        if duplicateExists {
            validationMessage = "This number is already used in this category."
            showValidationError = true
            return
        }
        
        target.name = trimmedName
        target.number = newNumber
        
        do {
            try context.save()
            editingAnimal = nil
        } catch {
            validationMessage = "Failed to save changes: \(error.localizedDescription)"
            showValidationError = true
        }
    }
    
    private func delete(_ animal: AnimalModel) {
        context.delete(animal)
        do {
            try context.save()
        } catch {
            validationMessage = "Failed to delete item: \(error.localizedDescription)"
            showValidationError = true
        }
    }
}
