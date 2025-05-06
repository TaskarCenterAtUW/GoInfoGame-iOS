

import SwiftUI
import osmparser

struct UndoItem: Identifiable {
    let elementId: Int
    let type: ElementType
    let changedKeys: [String]

    var id: String { "\(type)-\(elementId)" } // unique identifier
}

struct UndoSidebarView: View {
    let undoItems: [UndoItem]
    var onUndo: (Int, ElementType) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔄 Undo Edits")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }

            ScrollView {
                ForEach(undoItems) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(item.type == .way ? "Way" : "Node") #\(item.elementId)")
                            .font(.subheadline)
                            .bold()

                        if !item.changedKeys.isEmpty {
                            Text("Changed:")
                                .font(.caption)
                                .foregroundColor(.gray)

                            ForEach(item.changedKeys, id: \.self) { key in
                                Text("• \(key)")
                                    .font(.caption)
                            }
                        }

                        Button("Revert") {
                            onUndo(item.elementId, item.type)
                        }
                        .font(.caption)
                        .padding(6)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            Spacer()
        }
        .padding()
        .frame(width: 240)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
