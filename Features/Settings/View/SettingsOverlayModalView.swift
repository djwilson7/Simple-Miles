import SwiftUI

struct SettingsOverlayModalView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var isVisible: Bool

    var body: some View {
        ZStack {
            if isVisible {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()

                modalContent
                    .padding(.horizontal, 20)
                    .transition(.scale)
                    .animation(.easeInOut(duration: 0.25), value: isVisible)
            }
        }
    }

    private var modalContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header
                Divider()
                    .background(Color.secondary.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        recordingSection
                        sectionDivider
                        displaySection
                        sectionDivider
                        classificationSection
                        sectionDivider
                        exportSection
                        sectionDivider
                        privacySection
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .frame(width: geometry.size.width * 0.9)
            .frame(maxHeight: .infinity)
            .padding(.vertical, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var header: some View {
        HStack {
            Text("Settings")
                .font(SettingsFontStyle.sectionHeader)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                isVisible = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var sectionDivider: some View {
        GeometryReader { geometry in
            Divider()
                .frame(width: geometry.size.width * 0.6, height: 1)
                .background(Color.secondary.opacity(0.2))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 1)
    }

    // MARK: - Recording

    private var recordingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                motionSenitivity
                pauseTimer
                minimumTripDistance
                baseSpeedThreshold
                baseDistanceThreshold
            }
        } header: {
            Text("Trip Recording")
                .font(SettingsFontStyle.sectionHeader)
        }
    }

    private var motionSenitivity: some View {
        labeledPicker(
            title: "Motion Sensitivity",
            description: viewModel.motionSensitivity.description,
            selection: $viewModel.motionSensitivity,
            options: MotionSensitivityLevel.allCases
        )
    }

    private var pauseTimer: some View {
        labeledStepper(
            title: "Pause Timer",
            description: "Inactivity session end timer.",
            valueLabel: "\(Int(viewModel.pauseDuration / 60))m",
            value: $viewModel.pauseDuration,
            range: 60...3600,
            step: 60
        )
    }


    private var minimumTripDistance: some View {
        labeledStepper(
            title: "Min Trip Distance",
            description: "Set to ignore short trips.",
            valueLabel: String(format: "%.2f", viewModel.minimumTripDistance) + " mi",
            value: $viewModel.minimumTripDistance,
            range: 0...10,
            step: 0.25
        )
    }

    private var baseSpeedThreshold: some View {
        labeledStepper(
            title: "Start Speed",
            description: "Minimum auto start speed.",
            valueLabel: String(format: "%.1f", floor(viewModel.baseSpeedThreshold * 2.23694)) + " mph",
            value: Binding<Double>(
                get: { viewModel.baseSpeedThreshold * 2.23694 },
                set: { viewModel.baseSpeedThreshold = $0 / 2.23694 }
            ),
            range: 4...16,
            step: 1
        )
    }

    private var baseDistanceThreshold: some View {
        labeledStepper(
            title: "Start Distance",
            description: "Minimum auto start distance.",
            valueLabel: String(format: "%.2f", viewModel.baseDistanceThreshold * 0.000621371) + " mi",
            value: Binding<Double>(
                get: { viewModel.baseDistanceThreshold * 0.000621371 },
                set: { viewModel.baseDistanceThreshold = $0 / 0.000621371 }
            ),
            range: 0.25...1.0,
            step: 0.05
        )
    }

    // MARK: - Display

    private var displaySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                distanceUnits
                timeFormatPreference
                systemColorTheme
                accessibilityColorTheme
                appColorTheme
            }
        } header: {
            Text("Display")
                .font(SettingsFontStyle.sectionHeader)
        }
    }

    private var distanceUnits: some View {
        labeledToggle(
            title: "Distance Unit",
            description: "Toggle miles/kilometers",
            value: viewModel.distanceUnit,
            onValue: DistanceUnit.miles,
            offValue: DistanceUnit.kilometers,
            binding: $viewModel.distanceUnit,
            toggleLabel: viewModel.distanceUnit.abbreviation
        )
    }

    private var timeFormatPreference: some View {
        labeledToggle(
            title: "Time Format",
            description: "Preferred time display",
            value: viewModel.timeFormat,
            onValue: TimeFormat.twelveHour,
            offValue: TimeFormat.twentyFourHour,
            binding: $viewModel.timeFormat,
            toggleLabel: viewModel.timeFormat.label
        )
    }

    private var systemColorTheme: some View {
        labeledPicker(
            title: "System Color",
            description: "System theme.",
            selection: $viewModel.systemColorTheme,
            options: SystemColorTheme.allCases
        )
    }

    private var accessibilityColorTheme: some View {
        labeledPicker(
            title: "Accessibility Color",
            description: "Color-blind and contrast aid.",
            selection: $viewModel.accessibilityColorTheme,
            options: AccessibilityColorTheme.allCases
        )
    }

    private var appColorTheme: some View {
        labeledPicker(
            title: "App Color",
            description: "Preferred theme.",
            selection: $viewModel.appColorTheme,
            options: AppColorTheme.allCases
        )
    }

    

    // MARK: - Export
    
    private var exportSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                includeRawCoordinates
                exportFieldsToInclude
            }
        } header: {
            Text("Export")
                .font(SettingsFontStyle.sectionHeader)
        }
    }
    
    private var includeRawCoordinates: some View {
        Toggle("Include Raw Coordinates", isOn: $viewModel.includeRawCoordinates)
    }
    
    private var exportFieldsToInclude: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Export Fields")
                    .font(SettingsFontStyle.settingTitle)
                Text("Included in file output.")
                    .font(SettingsFontStyle.settingDescription)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            ForEach(ExportField.allCases, id: \.self) { field in
                Button(action: {
                    if viewModel.exportFieldOptions.contains(field) {
                        viewModel.exportFieldOptions.remove(field)
                    } else {
                        viewModel.exportFieldOptions.insert(field)
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.exportFieldOptions.contains(field) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(viewModel.exportFieldOptions.contains(field) ? .accentColor : .secondary)
                        Text(field.rawValue.capitalized)
                            .font(SettingsFontStyle.userInput)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    

    // MARK: - Classification

    private var classificationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                defaultTripStyle
                businessMode
                probabilityAutoTagging
                classificiationMode
                setCustomLabels
            }
        } header: {
            Text("Classification")
                .font(SettingsFontStyle.sectionHeader)
        }
    }

    private var defaultTripStyle: some View {
        labeledPicker(
            title: "Default Trip Type",
            description: "Used for all new trips.",
            selection: $viewModel.defaultTripType,
            options: TripType.allCases
        )
    }

    private var businessMode: some View {
        labeledToggle(
            title: "Business Mode",
            description: "All trips marked business",
            value: viewModel.businessModeEnabled,
            onValue: true,
            offValue: false,
            binding: $viewModel.businessModeEnabled
        )
    }

    private var probabilityAutoTagging: some View {
        labeledToggle(
            title: "Probabilistic Auto-Tagging",
            description: "Smart trip classification",
            value: viewModel.useProbabilisticTagging,
            onValue: true,
            offValue: false,
            binding: $viewModel.useProbabilisticTagging
        )
    }

    private var classificiationMode: some View {
        labeledPicker(
            title: "Classification Mode",
            description: "Trip grouping behavior",
            selection: $viewModel.classificationMode,
            options: ClassificationMode.allCases
        )
    }


    private var setCustomLabels: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Custom Labels")
                    .font(SettingsFontStyle.settingTitle)
                Text("Optional trip tags.")
                    .font(SettingsFontStyle.settingDescription)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            ForEach(Array(viewModel.customLabels.enumerated()), id: \.offset) { index, label in
                TextField("Label \(index + 1)", text: Binding(
                    get: { viewModel.customLabels[index] },
                    set: { viewModel.customLabels[index] = $0 }
                ))
                .font(SettingsFontStyle.userInput)
            }

            Button("Add Label") {
                viewModel.customLabels.append("")
            }
            .font(.footnote)
        }
    }


    // MARK: - Privacy

    private var privacySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                dataSharingLevel
            }
        } header: {
            Text("Privacy")
                .font(SettingsFontStyle.sectionHeader)
        }
    }
    
    private var dataSharingLevel: some View {
        labeledPicker(
            title: "Data Sharing Level",
            description: "Control what is shared",
            selection: $viewModel.privacyConsentLevel,
            options: PrivacyConsentLevel.allCases
        )
    }
    
//MARK: -- Setting Builders
    
    private func labeledToggle<T: Equatable>(
        title: String,
        description: String,
        value: T,
        onValue: T,
        offValue: T,
        binding: Binding<T>,
        toggleLabel: String? = nil
    ) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SettingsFontStyle.settingTitle)
                Text(description)
                    .font(SettingsFontStyle.settingDescription)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .layoutPriority(1)

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                if let toggleLabel = toggleLabel {
                    Text(toggleLabel)
                        .font(SettingsFontStyle.settingDescription)
                        .lineLimit(1)
                }

                Toggle("", isOn: Binding<Bool>(
                    get: { binding.wrappedValue == onValue },
                    set: { binding.wrappedValue = $0 ? onValue : offValue }
                ))
                .labelsHidden()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    
    private func labeledStepper(
        title: String,
        description: String,
        valueLabel: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(title): \(valueLabel)")
                    .font(SettingsFontStyle.settingTitle)
                Text(description)
                    .font(SettingsFontStyle.settingDescription)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .layoutPriority(1)

            Spacer(minLength: 12)

            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
        }
    }

    private func labeledPicker<T: Hashable & CaseIterable & CustomStringConvertible>(
        title: String,
        description: String,
        selection: Binding<T>,
        options: T.AllCases
    ) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SettingsFontStyle.settingTitle)
                Text(description)
                    .font(SettingsFontStyle.settingDescription)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }.layoutPriority(1)
            Spacer()
            Picker("", selection: selection) {
                ForEach(Array(options), id: \.self) { option in
                    Text(option.description).tag(option)
                }
            }
            .pickerStyle(.menu)
            .font(SettingsFontStyle.pickerText)
        }
    }
}

#Preview {
    SettingsOverlayModalView(viewModel: SettingsViewModel(), isVisible: .constant(true))
}
