//
//  EarningsView.swift
//  WorkingHour
//
//  Created by Assistant on 2026/07/16.
//

import Komponents
import SwiftData
import SwiftUI

enum EarningsPeriod: Int, CaseIterable, Identifiable {
    case week = 0
    case month = 1
    case year = 2

    var id: Int { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .week: "Earnings.Period.Week"
        case .month: "Earnings.Period.Month"
        case .year: "Earnings.Period.Year"
        }
    }

    /// The calendar component spanning this period.
    var component: Calendar.Component {
        switch self {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }

    /// The unit each chart bar represents.
    var chartUnit: Calendar.Component {
        switch self {
        case .week, .month: .day
        case .year: .month
        }
    }

    /// The date interval containing `date` for this period.
    func interval(containing date: Date) -> DateInterval {
        Calendar.current.dateInterval(of: component, for: date)
            ?? DateInterval(start: date, duration: 0)
    }
}

struct EarningsView: View {
    @State private var selectedPeriod: EarningsPeriod = .month

    var body: some View {
        NavigationStack {
            EarningsList(period: selectedPeriod)
                .navigationTitle("ViewTitle.Earnings")
                .toolbarTitleDisplayMode(.inlineLarge)
                .safeAreaInset(edge: .top, spacing: 0.0) {
                    Picker("Earnings.Period", selection: $selectedPeriod) {
                        ForEach(EarningsPeriod.allCases) { period in
                            Text(period.titleKey)
                                .tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20.0)
                    .padding(.vertical, 8.0)
                }
        }
    }
}

struct EarningsList: View {
    @Query private var entries: [ClockEntry]

    // Local copies refreshed on appear: SettingsManager properties are
    // UserDefaults-backed computed properties, so Observation cannot
    // invalidate this view when they change elsewhere (same pattern as
    // MoreView).
    @State private var hourlyRate: Double = 0.0
    @State private var overtimeMultiplier: Double = 1.0
    @State private var currencyCode: String = "USD"
    @State private var standardWorkingHours: TimeInterval = 8 * 3600
    @State private var roundingMinutes: Int = 0

    let period: EarningsPeriod

    private var isEarningsTrackingEnabled: Bool {
        hourlyRate > 0
    }

    init(period: EarningsPeriod) {
        self.period = period

        let interval = period.interval(containing: .now)
        let startDate = interval.start
        let endDate = interval.end
        let predicate = #Predicate<ClockEntry> { entry in
            if let clockInTime = entry.clockInTime {
                clockInTime >= startDate && clockInTime < endDate
            } else {
                false
            }
        }
        _entries = Query(filter: predicate, sort: [SortDescriptor(\.clockInTime)])
    }

    private var summary: EarningsSummary {
        EarningsCalculator.summarize(
            entries,
            standardWorkingHours: standardWorkingHours,
            hourlyRate: hourlyRate,
            overtimeMultiplier: overtimeMultiplier,
            roundingMinutes: roundingMinutes
        )
    }

    var body: some View {
        List {
            let summary = self.summary

            // Estimated earnings, front and center
            if isEarningsTrackingEnabled {
                Section {
                    VStack(alignment: .leading, spacing: 4.0) {
                        Text("Earnings.TotalEarnings")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text(summary.totalPay, format: .currency(code: currencyCode))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .contentTransition(.numericText())
                    }
                    .padding(.vertical, 4.0)
                }
            } else {
                Section {
                    NavigationLink {
                        PaySettingsView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4.0) {
                            Text("Earnings.SetupPrompt")
                                .fontWeight(.semibold)
                            Text("Earnings.SetupPrompt.Message")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4.0)
                    }
                }
            }

            // Hours chart
            Section {
                if summary.daysWorked == 0 {
                    Text("Earnings.NoData")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    EarningsChart(
                        entries: entries,
                        period: period,
                        standardWorkingHours: standardWorkingHours,
                        roundingMinutes: roundingMinutes
                    )
                }
            } header: {
                ListSectionHeader(text: "Earnings.Section.Hours")
            }

            // Working time stats
            Section {
                LabeledContent("Earnings.HoursWorked", value: formatTimeInterval(summary.totalTime))
                LabeledContent("Earnings.Overtime", value: formatTimeInterval(summary.overtime))
                LabeledContent("Earnings.DaysWorked", value: summary.daysWorked, format: .number)
                LabeledContent("Earnings.AveragePerDay", value: formatTimeInterval(summary.averageTimePerDay))
            } header: {
                ListSectionHeader(text: "Earnings.Section.Summary")
            }

            // Pay breakdown
            if isEarningsTrackingEnabled {
                Section {
                    LabeledContent("Earnings.RegularPay") {
                        Text(summary.regularPay, format: .currency(code: currencyCode))
                    }
                    LabeledContent("Earnings.OvertimePay") {
                        Text(summary.overtimePay, format: .currency(code: currencyCode))
                    }
                    LabeledContent("Earnings.TotalPay") {
                        Text(summary.totalPay, format: .currency(code: currencyCode))
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                } header: {
                    ListSectionHeader(text: "Earnings.Section.Breakdown")
                } footer: {
                    Text("Earnings.Estimate.Footer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    NavigationLink("Earnings.PaySettings") {
                        PaySettingsView()
                    }
                }
            }
        }
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        let settingsManager = SettingsManager.shared
        hourlyRate = settingsManager.hourlyRate
        overtimeMultiplier = settingsManager.overtimeRateMultiplier
        currencyCode = settingsManager.currencyCode
        standardWorkingHours = settingsManager.standardWorkingHours
        roundingMinutes = settingsManager.timeRoundingMinutes
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: max(0, interval)) ?? ""
    }
}
