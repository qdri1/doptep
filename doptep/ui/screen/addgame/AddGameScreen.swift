//
//  AddGameScreen.swift
//  doptep
//

import SwiftUI

struct AddGameScreen: View {
    @StateObject private var viewModel: AddGameViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AddGameViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @State private var showColorsSheet = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(spacing: 0) {
                    gameNameField
                    timeField

                    if viewModel.screenStateType == .add {
                        gameFormatSection
                        teamQuantitySection
                        gameRulesSection
                    }

                    teamsTabView
                }
            }
        }
        .background(AppColor.background)
        .navigationBarHidden(true)
        .sheet(isPresented: $showColorsSheet) {
            teamColorsSheet
        }
        .snackbar(message: $viewModel.snackbarMessage)
        .onChange(of: viewModel.effect) { _, effect in
            handleEffect(effect)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                viewModel.send(.closeScreen)
            } label: {
                Image(systemName: "arrow.left")
                    .font(.titleLarge)
                    .foregroundColor(AppColor.onSurface)
            }

            Text(viewModel.screenStateType == .add
                 ? NSLocalizedString("add_game", comment: "")
                 : NSLocalizedString("update_game", comment: ""))
                .font(.titleMedium)
                .foregroundColor(AppColor.onSurface)
                .frame(maxWidth: .infinity)

            Button {
                viewModel.send(.onFinishClicked)
            } label: {
                Image(systemName: "checkmark")
                    .font(.titleLarge)
                    .foregroundColor(AppColor.onSurface)
            }
        }
        .padding()
        .background(AppColor.surface)
    }

    private var gameNameField: some View {
        TextField(NSLocalizedString("game_name", comment: ""), text: Binding(
            get: { viewModel.gameNameFieldState },
            set: { viewModel.send(.onGameTextValueChanged(value: $0)) }
        ))
        .textFieldStyle(RoundedTextFieldStyle())
        .overlay(alignment: .trailing) {
            if !viewModel.gameNameFieldState.isEmpty {
                Button { viewModel.send(.onGameTextValueChanged(value: "")) } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColor.onSurfaceVariant)
                }
                .padding(.trailing, 16)
            }
        }
        .padding()
    }

    private var timeField: some View {
        TextField(NSLocalizedString("game_time", comment: ""), text: Binding(
            get: { viewModel.timeInMinuteFieldState },
            set: { viewModel.send(.onTimeTextValueChanged(value: $0)) }
        ))
        .keyboardType(.numberPad)
        .textFieldStyle(RoundedTextFieldStyle())
        .overlay(alignment: .trailing) {
            if !viewModel.timeInMinuteFieldState.isEmpty {
                Button { viewModel.send(.onTimeTextValueChanged(value: "")) } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColor.onSurfaceVariant)
                }
                .padding(.trailing, 16)
            }
        }
        .padding(.horizontal)
    }

    private var gameFormatSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("game_format", comment: ""))
                .font(.bodyMedium)
                .foregroundColor(AppColor.onSurface)
                .padding(.horizontal)
                .padding(.top)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(GameFormat.allCases, id: \.self) { format in
                        VStack {
                            Text(format.rawValue)
                                .font(.bodyMedium)
                                .foregroundColor(format == viewModel.gameFormatState ? AppColor.primary : AppColor.outline)
                            
                            RadioButton(isSelected: format == viewModel.gameFormatState) {
                                viewModel.send(.onGameFormatSelected(format: format))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(AppColor.surface)
        .padding(.top)
    }

    private var teamQuantitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("team_quantity", comment: ""))
                .font(.bodyMedium)
                .foregroundColor(AppColor.onSurface)
                .padding(.horizontal)
                .padding(.top)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(TeamQuantity.allCases, id: \.self) { quantity in
                        TeamQuantityItem(
                            quantity: quantity,
                            isSelected: quantity == viewModel.teamQuantityState,
                            onSelect: {
                                viewModel.send(.onTeamQuantitySelected(teamQuantity: quantity))
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(AppColor.surface)
        .padding(.top)
    }

    private var gameRulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("game_rules", comment: ""))
                .font(.bodyMedium)
                .foregroundColor(AppColor.onSurface)
                .padding(.horizontal)
                .padding(.top)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(currentRules, id: \.localizationKey) { rule in
                    HStack {
                        RadioButton(isSelected: areRulesEqual(rule, viewModel.gameRuleState)) {
                            viewModel.send(.onGameRuleSelected(rule: rule))
                        }
                        Text(NSLocalizedString(rule.localizationKey, comment: ""))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.bodyMedium)
                            .foregroundColor(areRulesEqual(rule, viewModel.gameRuleState) ? AppColor.primary : AppColor.outline)
                            .onTapGesture {
                                viewModel.send(.onGameRuleSelected(rule: rule))
                            }
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
        .background(AppColor.surface)
        .padding(.top)
    }

    private var currentRules: [GameRule] {
        switch viewModel.gameRuleState {
        case is GameRuleTeam2:
            return GameRuleTeam2.allCases
        case is GameRuleTeam3:
            return GameRuleTeam3.allCases
        case is GameRuleTeam4:
            return GameRuleTeam4.allCases
        default:
            return GameRuleTeam3.allCases
        }
    }

    private func areRulesEqual(_ lhs: GameRule, _ rhs: GameRule) -> Bool {
        lhs.localizationKey == rhs.localizationKey
    }

    private var teamsTabView: some View {
        VStack(spacing: 0) {
            tabBar
            tabContent
        }
        .padding(.top)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<viewModel.teamQuantityState.rawValue, id: \.self) { index in
                Button {
                    viewModel.send(.onTeamTabClicked(tabIndex: index))
                } label: {
                    VStack(spacing: 12) {
                        Text(String(format: NSLocalizedString("team_number", comment: ""), "\(index + 1)"))
                            .font(.bodyMedium)
                            .foregroundColor(viewModel.selectedTeamTabIndex == index ? AppColor.primary : AppColor.onSurface)
                        Rectangle()
                            .fill(viewModel.selectedTeamTabIndex == index ? AppColor.primary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top)
        .background(AppColor.surface)
    }

    private var tabContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                teamColorButton
                teamNameField
            }

            ForEach(0..<playerFieldsCount, id: \.self) { fieldIndex in
                playerField(at: fieldIndex)
            }

            addPlayerButton
        }
        .padding()
    }

    private var playerFieldsCount: Int {
        guard viewModel.selectedTeamTabIndex < viewModel.playersTextFields.count else { return 0 }
        return viewModel.playersTextFields[viewModel.selectedTeamTabIndex].count
    }

    private var teamColorButton: some View {
        Button {
            viewModel.send(.onTeamColorClicked)
        } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(currentTeamColor)
                .frame(width: 56, height: 56)
        }
    }

    private var currentTeamColor: Color {
        guard viewModel.selectedTeamTabIndex < viewModel.teamColors.count else {
            return TeamColor.red.color
        }
        return viewModel.teamColors[viewModel.selectedTeamTabIndex].color
    }

    private var teamNameField: some View {
        let binding = Binding<String>(
            get: {
                guard viewModel.selectedTeamTabIndex < viewModel.teamNameFields.count else { return "" }
                return viewModel.teamNameFields[viewModel.selectedTeamTabIndex]
            },
            set: { newValue in
                viewModel.send(.onTeamNameValueChanged(tabIndex: viewModel.selectedTeamTabIndex, value: newValue))
            }
        )

        return TextField(NSLocalizedString("team_name", comment: ""), text: binding)
            .textFieldStyle(RoundedTextFieldStyle())
            .overlay(alignment: .trailing) {
                if !binding.wrappedValue.isEmpty {
                    Button { binding.wrappedValue = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColor.onSurfaceVariant)
                    }
                    .padding(.trailing, 16)
                }
            }
    }

    private func playerField(at fieldIndex: Int) -> some View {
        let tabIndex = viewModel.selectedTeamTabIndex
        let binding = Binding<String>(
            get: {
                guard tabIndex < viewModel.playersTextFields.count,
                      fieldIndex < viewModel.playersTextFields[tabIndex].count else { return "" }
                return viewModel.playersTextFields[tabIndex][fieldIndex]
            },
            set: { newValue in
                viewModel.send(.onPlayerNameValueChanged(tabIndex: tabIndex, fieldIndex: fieldIndex, value: newValue))
            }
        )

        return TextField(
            String(format: NSLocalizedString("player_number", comment: ""), "\(fieldIndex + 1)"),
            text: binding
        )
        .textFieldStyle(RoundedTextFieldStyle())
        .overlay(alignment: .trailing) {
            if !binding.wrappedValue.isEmpty {
                Button { binding.wrappedValue = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColor.onSurfaceVariant)
                }
                .padding(.trailing, 16)
            }
        }
    }

    private var addPlayerButton: some View {
        Button {
            viewModel.send(.onAddPlayerClicked(tabIndex: viewModel.selectedTeamTabIndex))
        } label: {
            Text(NSLocalizedString("add_player", comment: ""))
                .font(.bodyMedium)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .padding(.top, 4)
        .padding(.bottom, 16)
    }

    private var teamColorsSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("choose_team_color", comment: ""))
                .font(.titleMedium)
                .padding(.horizontal)
                .padding(.top)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TeamColor.allCases, id: \.self) { color in
                        Button {
                            viewModel.send(.onTeamColorSelected(color: color))
                            showColorsSheet = false
                        } label: {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(color.color)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
                .frame(height: 32)
        }
        .presentationDetents([.height(150)])
    }

    private func handleEffect(_ effect: AddGameEffect?) {
        guard let effect = effect else { return }
        viewModel.effect = nil

        switch effect {
        case .showColorsBottomSheet:
            showColorsSheet = true
        case .showSnackbar(let message):
            viewModel.snackbarMessage = message
        case .openGameScreen:
            dismiss()
        case .closeScreen:
            dismiss()
        case .closeScreenWithResult:
            dismiss()
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppColor.surface)
            .cornerRadius(16)
    }
}

struct RadioButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .stroke(isSelected ? AppColor.primary : AppColor.outline, lineWidth: 2)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .fill(isSelected ? AppColor.primary : Color.clear)
                        .frame(width: 10, height: 10)
                )
        }
    }
}

struct SnackbarModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if let message = message {
                Text(message)
                    .font(.bodyMedium)
                    .foregroundColor(AppColor.onPrimary)
                    .padding()
                    .background(AppColor.inverseSurface)
                    .cornerRadius(8)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                self.message = nil
                            }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: message)
    }
}

extension View {
    func snackbar(message: Binding<String?>) -> some View {
        modifier(SnackbarModifier(message: message))
    }
}

struct TeamQuantityItem: View {
    let quantity: TeamQuantity
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack {
            Text("\(quantity.rawValue)")
                .font(.bodyMedium)
                .foregroundColor(isSelected ? AppColor.primary : AppColor.outline)

            RadioButton(isSelected: isSelected, action: onSelect)
        }
    }
}
