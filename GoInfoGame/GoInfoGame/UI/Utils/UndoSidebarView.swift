

import SwiftUI
import osmparser

struct UndoItem: Identifiable {
    enum TagAction: String {
        case added = "Added"
        case modified = "Modified"
    }
    
    let elementId: Int
    let type: ElementType
    let changedKeys: [String]
    var id: String
    let timestamp: Date
    let questType: String?
    let tags: [(action: TagAction, key: String, value: String)]
    let iconName: String
}

struct UndoSidebarView: View {
    @State private var undoItems: [UndoItem] = []
    var onUndo: (String) -> Void
    var onClose: () -> Void
    var onItemSelected: (UndoItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.title)
                    
                Text("Undo Edits")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(Asset.Colors.accentPink.swiftUIColor)
                }
            }
            .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)

            ScrollView {
                ForEach(undoItems) { item in
                    Button(action: {
                        onItemSelected(item)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(item.type == .way ? "Way" : "Node") #\(String(item.elementId))")
                                .font(.subheadline)
                                .bold()

                            if !item.changedKeys.isEmpty {
                                Text("Tap to view changes")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }

            Spacer()
        }
        .onAppear {
            undoItems = MapUndoManager.shared.getUndoItems()
        }
        .padding()
        .frame(width: 240)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
#Preview {
    UndoSidebarView(
        
        onUndo: {_ in
            
        },
        onClose: {},
        onItemSelected: {_ in })
    
}


