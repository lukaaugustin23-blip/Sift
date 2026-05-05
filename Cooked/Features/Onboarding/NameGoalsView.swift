import SwiftUI

struct NameGoalsView: View {
    @Binding var name: String
    @Binding var goals: [String]           // always length 3, empty strings = unfilled

    var onContinue: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name, goal(Int)
    }

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            DS.Color.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xl) {

                    // Header
                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        Text("WHO ARE YOU?")
                            .labelStyle()
                            .foregroundStyle(DS.Color.inkSecondary)

                        Text("Let's start with the basics.")
                            .font(DS.Font.heading(24))
                            .foregroundStyle(DS.Color.ink)
                    }

                    // Name
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("YOUR NAME")
                            .labelStyle()
                            .foregroundStyle(DS.Color.inkSecondary)

                        TextField("", text: $name, prompt: Text("Enter your name")
                            .foregroundStyle(DS.Color.inkSecondary))
                            .font(DS.Font.bodyMedium(16))
                            .foregroundStyle(DS.Color.ink)
                            .padding(DS.Space.md)
                            .background(DS.Color.bgSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .goal(0) }
                    }

                    // Goals
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("YOUR GOALS")
                                .labelStyle()
                                .foregroundStyle(DS.Color.inkSecondary)
                            Text("What are you working toward? (up to 3)")
                                .font(DS.Font.body(13))
                                .foregroundStyle(DS.Color.inkSecondary)
                        }

                        ForEach(0..<3, id: \.self) { i in
                            goalField(index: i)
                        }
                    }

                    Spacer(minLength: DS.Space.xxl)
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.top, DS.Space.xl)
                .padding(.bottom, 120)
            }

            // Continue button pinned to bottom
            VStack {
                Spacer()
                continueButton
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.bottom, DS.Space.xxl)
                    .background(
                        LinearGradient(
                            colors: [DS.Color.bg.opacity(0), DS.Color.bg],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
            }
        }
        .onAppear {
            if goals.count < 3 { goals = Array(repeating: "", count: 3) }
            focusedField = .name
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func goalField(index: Int) -> some View {
        HStack(spacing: DS.Space.sm) {
            Text("\(index + 1)")
                .font(DS.Font.data(12))
                .foregroundStyle(DS.Color.inkSecondary)
                .frame(width: 20)

            TextField("", text: Binding(
                get: { goals.indices.contains(index) ? goals[index] : "" },
                set: { goals[index] = $0 }
            ), prompt: Text("Optional goal \(index + 1)")
                .foregroundStyle(DS.Color.inkSecondary))
                .font(DS.Font.body(15))
                .foregroundStyle(DS.Color.ink)
                .padding(DS.Space.md)
                .background(DS.Color.bgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tag))
                .focused($focusedField, equals: .goal(index))
                .submitLabel(index < 2 ? .next : .done)
                .onSubmit {
                    if index < 2 { focusedField = .goal(index + 1) }
                    else { focusedField = nil }
                }
        }
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("CONTINUE →")
                .font(DS.Font.label(11))
                .foregroundStyle(canContinue ? DS.Color.darkText : DS.Color.inkSecondary)
                .tracking(3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.lg)
                .background(canContinue ? DS.Color.dark : DS.Color.bgSecondary)
                .clipShape(Capsule())
        }
        .disabled(!canContinue)
        .animation(.easeInOut(duration: 0.2), value: canContinue)
    }
}

#Preview {
    NameGoalsView(
        name: .constant("Luka"),
        goals: .constant(["Get into med school", "", ""]),
        onContinue: {}
    )
}
