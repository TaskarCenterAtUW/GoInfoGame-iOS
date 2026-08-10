

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
    /// True for a feature created via Add Feature — undoing it deletes the element
    /// outright rather than reverting a tag edit, so the UI offers "Delete" instead
    /// of "Revert".
    var isCreatedElement: Bool = false
}

struct UndoSidebarView: View {
    @State private var undoItems: [UndoItem] = []
    var onUndo: (String) -> Void
    var onClose: () -> Void
    var onItemSelected: (UndoItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Fixed size (doesn't scale with Dynamic Type) so this decorative icon can't
                // balloon at large accessibility sizes and squeeze the title into a column too
                // narrow to hold even a single word — see the fixed sidebar width below.
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 24))
                    .accessibilityHidden(true)

                Text("Undo Edits")
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(Asset.Colors.accentPink.swiftUIColor)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
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
                                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)

                            if !item.changedKeys.isEmpty {
                                Text(item.isCreatedElement ? "New feature — tap to delete" : "Tap to view changes")
                                    .font(.caption)
                                    .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
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
        .frame(minWidth: 240, maxWidth: 320)
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


