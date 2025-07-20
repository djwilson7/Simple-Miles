// Features/Settings/Views/SettingsOverlayModalView.swift
import SwiftUI

struct SettingsOverlayModalView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var isVisible: Bool

    var body: some View {
        ZStack {
            if isVisible {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isVisible = false
                    }

                modalContent
                    .transition(.scale)
                    .animation(.easeInOut(duration: 0.25), value: isVisible)
            }
        }
    }

    private var modalContent: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    isVisible = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

            ScrollView {
                settingsForm
                    .padding()
            }
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: 500)
    }

    private var settingsForm: some View {
        VStack(alignment: .leading, spacing: 32) {

            // MARK: - Recording
            Section {
                Picker("Motion Sensitivity", selection: $viewModel.motionSensitivity) {
                    ForEach(MotionSensitivityLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level)
                    }
                }

                Stepper("Pause Timer: \(Int(viewModel.pauseDuration))s", value: $viewModel.pauseDuration, in: 60...1800, step: 30)

                Stepper("Minimum Trip Distance: \(String(format: "%.2f", viewModel.minimumTripDistance)) mi", value: $viewModel.minimumTripDistance, in: 0.1...10, step: 0.1)

                VStack(alignment: .leading) {
                    Text("Base Speed Threshold: \(String(format: "%.1f", viewModel.baseSpeedThreshold)) m/s")
                    Slider(value: $viewModel.baseSpeedThreshold, in: 0.5...10.0, step: 0.1)
                }

                VStack(alignment: .leading) {
                    Text("Base Distance Threshold: \(Int(viewModel.baseDistanceThreshold)) m")
                    Slider(value: $viewModel.baseDistanceThreshold, in: 10...200, step: 5)
                }
            } header: {
                Text("Recording").font(.headline)
            }

            // MARK: - Display
            Section {
                Picker("Distance Unit", selection: $viewModel.distanceUnit) {
                    ForEach(DistanceUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue.capitalized).tag(unit)
                    }
                }

                Picker("Time Format", selection: $viewModel.timeFormat) {
                    Text("12-Hour").tag(TimeFormat.twelveHour)
                    Text("24-Hour").tag(TimeFormat.twentyFourHour)
                }

                Picker("Primary Theme", selection: $viewModel.primaryColorTheme) {
                    ForEach(ColorTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue.capitalized).tag(theme)
                    }
                }

                Picker("Secondary Theme", selection: $viewModel.secondaryColorTheme) {
                    ForEach(ColorTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue.capitalized).tag(theme)
                    }
                }
            } header: {
                Text("Display").font(.headline)
            }

            // MARK: - Export
            Section {
                Toggle("Include Raw Coordinates", isOn: $viewModel.includeRawCoordinates)

                Text("File Prefix")
                TextField("Trip_", text: $viewModel.defaultExportFileNamePrefix)

                Text("Export Fields")
                ForEach(ExportField.allCases, id: \.self) { field in
                    Toggle(field.rawValue.capitalized, isOn: Binding(
                        get: { viewModel.exportFieldOptions.contains(field) },
                        set: { isOn in
                            if isOn {
                                viewModel.exportFieldOptions.insert(field)
                            } else {
                                viewModel.exportFieldOptions.remove(field)
                            }
                        }
                    ))
                }
            } header: {
                Text("Export").font(.headline)
            }

            // MARK: - Classification
            Section {
                Picker("Default Trip Type", selection: $viewModel.defaultTripType) {
                    ForEach(TripType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }

                Toggle("Business Mode", isOn: $viewModel.businessModeEnabled)
                Toggle("Probabilistic Auto-Tagging", isOn: $viewModel.useProbabilisticTagging)

                Picker("Classification Mode", selection: $viewModel.classificationMode) {
                    ForEach(ClassificationMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Custom Labels")
                    ForEach(Array(viewModel.customLabels.enumerated()), id: \.offset) { index, label in
                        TextField("Label \(index + 1)", text: Binding(
                            get: { viewModel.customLabels[index] },
                            set: { viewModel.customLabels[index] = $0 }
                        ))
                    }
                    Button("Add Label") {
                        viewModel.customLabels.append("")
                    }
                }
            } header: {
                Text("Classification").font(.headline)
            }
        }
    }
}
