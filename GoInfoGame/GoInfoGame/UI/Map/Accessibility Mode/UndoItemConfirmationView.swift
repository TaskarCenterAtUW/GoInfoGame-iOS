//
//  UndoItemConfirmationView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 02/12/25.
//

import SwiftUI

struct UndoItemConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var onRevertChanges: () -> Void = { }
    private var onClose: () -> Void = { }

    private var undoItem: UndoItem

    /// Minimum room always reserved for the tags list, so it's never squeezed out
    /// entirely no matter how tall the header/footer content around it grows.
    private let minimumListAreaHeight: CGFloat = 150
    @State private var selectedDetent: PresentationDetent = .fraction(0.7)
    @State private var measuredHeaderHeight: CGFloat = 0
    @State private var measuredFooterHeight: CGFloat = 0

    init(undoItem: UndoItem, onRevertChanges: @escaping () -> Void, onClose: @escaping () -> Void ) {
        self.onRevertChanges = onRevertChanges
        self.onClose = onClose
        self.undoItem = undoItem
    }

    var body: some View {
        // The header (title/type/date) and footer (buttons) are measured so the sheet's
        // height is driven by their actual size, with a guaranteed minimum reserved for
        // the tags List in between — instead of a fixed 0.7 sheet fraction that could
        // squeeze the List down to nothing at large accessibility text, the same failure
        // mode ManageQuestsView had.
        VStack(spacing: 0) {
            headerContent
                .fixedSize(horizontal: false, vertical: true)
                .readHeight { newHeight in
                    guard newHeight > 0, abs(newHeight - measuredHeaderHeight) > 0.5 else { return }
                    measuredHeaderHeight = newHeight
                    updateDetent()
                }

            tagsList

            footerContent
                .fixedSize(horizontal: false, vertical: true)
                .readHeight { newHeight in
                    guard newHeight > 0, abs(newHeight - measuredFooterHeight) > 0.5 else { return }
                    measuredFooterHeight = newHeight
                    updateDetent()
                }
        }
        .padding()
        .presentationDetents([selectedDetent, .large], selection: $selectedDetent)
    }

    private func updateDetent() {
        guard measuredHeaderHeight > 0, measuredFooterHeight > 0 else { return }
        let screenHeight = UIScreen.main.bounds.height
        let target = measuredHeaderHeight + measuredFooterHeight + minimumListAreaHeight
        selectedDetent = .height(min(max(target, 300), screenHeight * 0.95))
    }

    private var headerContent: some View {
        VStack(alignment: .center, spacing: 20) {
            HStack(alignment: .center, content: {
                Text(L10n.Localizable.undoTheFollowingChanges)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 18, relativeTo: .headline))
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(L10n.Localizable.undoTheFollowingChanges)

                Spacer()

                CrossMarkButton(onDismiss: {
                    dismiss()
                    onClose()
                })
            })

            DottedLine()

            VStack(alignment: .leading, content: {
                HStack {
                    VStack(alignment: .leading, spacing: 10, content: {

                        HStack {
                            (
                                Text(L10n.Localizable.type)
                                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                                +
                                Text(": " + (undoItem.questType ?? "Not Avilable"))
                                    .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo: .headline))
                            )
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(L10n.Localizable.type): \(undoItem.questType ?? "Not Available")")
                        }

                        HStack {
                            (
                                Text(L10n.Localizable.dateTime)
                                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                                +
                                Text(": " + (undoItem.timestamp.formatted(date: .long, time: .shortened)))
                                    .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo: .headline))
                            )
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(L10n.Localizable.dateTime): \(undoItem.timestamp.formatted(date: .long, time: .shortened))")
                        }
                    })
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)

                    Spacer()

                    Image(undoItem.iconName)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(20)

                }
            })
        }
    }

    private var tagsList: some View {
        VStack(spacing: 0) {
            DottedLine()

            List {
                ForEach(undoItem.tags, id: \.key) { item in
                    EditedTagView(tagUpdate: item)
                        .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .listRowSpacing(10)
            .padding(.bottom, 20)
            .listRowSeparator(.hidden)
        }
    }

    private var footerContent: some View {
        VStack(spacing: 0) {
            DottedLine()
                .padding(.bottom, 20)

            // Side by side with no Spacer, each button gets only ~50% of the row's
            // width; at large accessibility text a two-word label like "Revert
            // Changes" can still need more than that, wrapping mid-word. Stacking
            // them instead gives each the full row width.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    revertChangesButton
                    cancelButton
                }
            } else {
                HStack {
                    revertChangesButton
                    cancelButton
                }
            }
        }
    }

    private var revertChangesButton: some View {
        Button {
            dismiss()
            onRevertChanges()
        } label: {
            ZStack {
                // A created feature has no prior tags to revert to — undoing it
                // deletes the element outright (see StoredChangeset.isCreatedElement).
                Text(undoItem.isCreatedElement ? "Delete Feature" : L10n.Localizable.revertChanges)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Asset.Colors.ff0041Red.swiftUIColor)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                    .cornerRadius(25)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .accessibilityLabel(Text(undoItem.isCreatedElement ? "Delete Feature" : L10n.Localizable.revertChanges))
            }
        }
    }

    private var cancelButton: some View {
        Button {
            dismiss()
            onClose()
        } label: {
            ZStack {
                Text(L10n.Localizable.cancel)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(25)
                    .overlay(content: {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Asset.Colors.huskyPurple.swiftUIColor, lineWidth: 2.0)
                            .background(.clear)
                    })
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                    .accessibilityLabel(Text(L10n.Localizable.cancel))

            }
        }
    }
}

#Preview {
    UndoItemConfirmationView(undoItem: UndoItem(elementId: 101, type: .node, changedKeys: ["key1", "Key2"], id: "402322", timestamp: Date(), questType: "Sidewalk", tags: [(.added, "Key1", "Value 1"), (.modified, "Key2", "Value 2")], iconName: "sidewalk"), onRevertChanges: {
    }, onClose: {
    })
}
