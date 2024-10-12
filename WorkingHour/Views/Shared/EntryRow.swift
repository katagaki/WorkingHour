//
//  EntryRow.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2024/10/11.
//

import SwiftUI

struct EntryRow: View {
    @State var entry: ClockEntry

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8.0) {
                HStack(alignment: .center, spacing: 12.0) {
                    VStack(alignment: .leading, spacing: 4.0) {
                        if let clockInTime = entry.clockInTime {
                            Text(clockInTime, style: .date)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text(clockInTime, style: .time)
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "arrow.right")
                    VStack(alignment: .trailing, spacing: 4.0) {
                        if let clockOutTime = entry.clockOutTime {
                            Text(clockOutTime, style: .date)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text(clockOutTime, style: .time)
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                HStack(alignment: .top, spacing: 4.0) {
                    Text("\(Image(systemName: "cup.and.heat.waves")) \(entry.breakTimeString())")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(Image(systemName: "clock")) \(entry.timeWorkedString())")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8.0)
                .background(.rowLabel)
                .clipShape(.rect(cornerRadius: 8.0))
            }
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
        }
    }
}
