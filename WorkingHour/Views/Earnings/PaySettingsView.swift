//
//  PaySettingsView.swift
//  WorkingHour
//
//  Created by Assistant on 2026/07/16.
//

import SwiftUI

struct PaySettingsView: View {
    @State private var settingsManager = SettingsManager.shared

    @State private var hourlyRate: Double = 0.0
    @State private var overtimeMultiplier: Double = 1.0
    @State private var currencyCode: String = "USD"

    private let selectableMultipliers: [Double] = [1.0, 1.25, 1.5, 1.75, 2.0]

    private var selectableCurrencyCodes: [String] {
        var codes = Locale.commonISOCurrencyCodes
        if !codes.contains(currencyCode) {
            codes.append(currencyCode)
            codes.sort()
        }
        return codes
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("PaySettings.HourlyRate")
                    Spacer()
                    TextField(
                        "PaySettings.HourlyRate",
                        value: $hourlyRate,
                        format: .number.precision(.fractionLength(0...2))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120.0)
                    Text(currencySymbol)
                        .foregroundStyle(.secondary)
                }

                Picker("PaySettings.Currency", selection: $currencyCode) {
                    ForEach(selectableCurrencyCodes, id: \.self) { code in
                        Text(currencyLabel(for: code))
                            .tag(code)
                    }
                }
            } header: {
                Text("PaySettings.Section.Rate")
            }

            Section {
                Picker("PaySettings.OvertimeMultiplier", selection: $overtimeMultiplier) {
                    ForEach(selectableMultipliers, id: \.self) { multiplier in
                        Text(multiplierLabel(for: multiplier))
                            .tag(multiplier)
                    }
                }
            } footer: {
                Text("PaySettings.OvertimeMultiplier.Footer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Earnings.PaySettings")
        .toolbarTitleDisplayMode(.inline)
        .onAppear {
            loadSettings()
        }
        .onChange(of: hourlyRate) { _, _ in
            saveSettings()
        }
        .onChange(of: overtimeMultiplier) { _, _ in
            saveSettings()
        }
        .onChange(of: currencyCode) { _, _ in
            saveSettings()
        }
    }

    private var currencySymbol: String {
        Locale.current.localizedCurrencySymbol(forCurrencyCode: currencyCode) ?? currencyCode
    }

    private func currencyLabel(for code: String) -> String {
        if let name = Locale.current.localizedString(forCurrencyCode: code) {
            return "\(code) — \(name)"
        }
        return code
    }

    private func multiplierLabel(for multiplier: Double) -> String {
        multiplier.formatted(.number.precision(.fractionLength(0...2))) + "×"
    }

    private func loadSettings() {
        hourlyRate = settingsManager.hourlyRate
        overtimeMultiplier = settingsManager.overtimeRateMultiplier
        currencyCode = settingsManager.currencyCode
    }

    private func saveSettings() {
        settingsManager.hourlyRate = max(0, hourlyRate)
        settingsManager.overtimeRateMultiplier = overtimeMultiplier
        settingsManager.currencyCode = currencyCode
    }
}

private extension Locale {
    /// The currency symbol for an arbitrary currency code (e.g. "$", "¥").
    func localizedCurrencySymbol(forCurrencyCode code: String) -> String? {
        var components = Locale.Components(locale: self)
        components.currency = Locale.Currency(code)
        return Locale(components: components).currencySymbol
    }
}
