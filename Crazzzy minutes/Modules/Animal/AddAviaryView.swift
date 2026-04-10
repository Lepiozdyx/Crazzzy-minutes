import SwiftUI
import SwiftData

struct AddAviaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    let initialType: AnimalType
    
    @State private var selectedType: AnimalType
    @State private var name: String = ""
    
    init(initialType: AnimalType) {
        self.initialType = initialType
        _selectedType = State(initialValue: initialType)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
            }
            .padding(.top, 14)
            .padding(.leading, 10)
            
            Spacer().frame(height: 36)
            
            Text("Select a category")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
            
            HStack(spacing: 14) {
                ForEach(AnimalType.allCases, id: \.self) { type in
                    Button {
                        selectedType = type
                    } label: {
                            Image(selectedType == type ?
                                  "\(selectedType.asset.dropLast())s" :
                                    type.asset
                            )
                                .resizable()
                                .scaledToFit()
                                .frame(width: 46, height: 46)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            
            Text("Enter the name")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.top, 34)
            
            HStack(spacing: 10) {
                TextField("", text: $name)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.black)
                
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.75, green: 0.84, blue: 0.90))
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            Button {
                save()
            } label: {
                Text("Save")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .frame(width: 136, height: 42)
                    .background(Color(red: 0.62, green: 0.69, blue: 0.50))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 74)
            
            Spacer()
        }
        .bg()
        .hideKeyboardOnTap()
        .navigationBarBackButtonHidden(true)
    }
    
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let aviary = AviaryModel(
            name: trimmed,
            animalType: selectedType,
            animals: []
        )
        
        context.insert(aviary)
        
        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to save AviaryModel: \(error.localizedDescription)")
        }
    }
}
