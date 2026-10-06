//
//  ShowQuestFormsView.swift
//  GoInfoGame
//
//  Created by Srikanth V on 05/10/26.
//

import SwiftUI

/// Profile → Show Quest Forms: lists the selected workspace's long form element types
/// and opens each one's long form as a preview. Nothing is submitted — on Submit, the
/// tags that would be written to a real element are shown in an alert instead.
struct ShowQuestFormsView: View {
    @Environment(\.dismiss) var dismiss

    /// False when Profile was opened from the workspace list — no workspace is loaded
    /// yet, so the list stays empty even if `longQuestModels` still holds a previous
    /// workspace's long form.
    let isWorkspaceSelected: Bool

    @ObservedObject private var questsRepository = QuestsRepository.shared

    @State private var searchText = ""

    @State private var selectedForm: QuestFormPreview?

    /// Set by the form's Submit, then moved to `previewAnswer` once the sheet has
    /// finished dismissing — an alert presented while the sheet is still on screen
    /// would be dropped.
    @State private var pendingPreviewAnswer: LongFormAnswer?

    @State private var previewAnswer: LongFormAnswer?

    private var elements: [LongFormElement] {
        guard isWorkspaceSelected else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return questsRepository.longQuestModels }
        return questsRepository.longQuestModels.filter { $0.elementType.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        Group {
            if elements.isEmpty {
                VStack {
                    Spacer()
                    Text("Nothing found")
                        .font(FontFamily.Lato.bold.swiftUIFont(size: 18, relativeTo: .headline))
                        .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List(elements, id: \.questQuery) { element in
                    Button {
                        selectedForm = QuestFormPreview(element: element)
                    } label: {
                        HStack(spacing: 12) {
                            ElementTypeIconView(iconName: LongElementQuest.iconName(elementType: element.elementType, elementTypeIcon: element.elementTypeIcon))
                            Text(element.elementType)
                                .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo: .body))
                                .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                            Spacer()
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(element.elementType)
                    .accessibilityHint("Shows the quest form preview")
                }
                .listStyle(.plain)
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .navigationBarBackButtonHidden()
        .navigationTitle("Show Quest Forms")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityLabel(L10n.Localizable.back)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Show Quest Forms")
                    .font(.headline)
                    .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            }
        }
        .sheet(item: $selectedForm, onDismiss: {
            previewAnswer = pendingPreviewAnswer
            pendingPreviewAnswer = nil
        }) { form in
            LongForm(elementName: form.element.elementType,
                     query: form.element.questQuery,
                     isPreviewMode: true,
                     action: { answer in
                pendingPreviewAnswer = answer
                selectedForm = nil
            })
            .presentationDetents([.fraction(0.7), .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
            .applyPresentationSizingPage()
        }
        .alert("Tagging", isPresented: Binding(
            get: { previewAnswer != nil },
            set: { if !$0 { previewAnswer = nil } }
        ), presenting: previewAnswer) { _ in
            Button("OK", role: .cancel) {}
        } message: { answer in
            Text(taggingSummary(for: answer))
        }
    }

    /// One line per tag the real submission would change, in the same ADD/DELETE form
    /// as Android. An empty value is how a cleared answer removes its tag on sync.
    private func taggingSummary(for answer: LongFormAnswer) -> String {
        var lines = answer.tags.sorted { $0.key < $1.key }.map { key, value in
            value.isEmpty ? "DELETE \"\(key)\"" : "ADD \"\(key)\"=\"\(value)\""
        }
        if answer.capturedImage != nil, let imageTagKey = answer.imageTagKey {
            lines.append("ADD \"\(imageTagKey)\"=\"<uploaded photo URL>\"")
        }
        return lines.joined(separator: "\n")
    }
}

private struct QuestFormPreview: Identifiable {
    let element: LongFormElement
    var id: String { element.questQuery }
}

/// Element type icon in its original asset colors, falling back to the remote
/// custom-icon / placeholder handling in `PresetIconView`.
private struct ElementTypeIconView: View {
    let iconName: String
    var size: CGFloat = 28

    var body: some View {
        if let localImage = UIImage(named: iconName) {
            Image(uiImage: localImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        } else {
            PresetIconView(iconName: iconName, size: size)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    NavigationView {
        ShowQuestFormsView(isWorkspaceSelected: true)
    }
}
