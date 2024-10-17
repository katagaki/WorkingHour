//
//  TimelineRow.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/10/17.
//

import SwiftUI

struct TimelineRow: View {
    var eventType: EventType
    @Binding var date: Date
    var validDateRanges: ClosedRange<Date>?

    init(_ eventType: EventType, date: Binding<Date>, in validDateRanges: ClosedRange<Date>? = nil) {
        self.eventType = eventType
        self._date = date
        self.validDateRanges = validDateRanges
    }

    var body: some View {
        HStack(alignment: .center, spacing: 18.0) {
            VStack(alignment: .center, spacing: 0.0) {
                Rectangle()
                    .foregroundStyle(AnyShapeStyle(lineStyle))
                    .frame(minWidth: 6.0, idealWidth: 6.0, maxWidth: 6.0, maxHeight: .infinity)
                    .overlay {
                        switch eventType {
                        case .start, .breakStart, .end:
                            Circle()
                                .foregroundStyle(.white)
                                .frame(width: 18.0, height: 18.0)
                                .overlay {
                                    Circle()
                                        .stroke(.gray, lineWidth: 2.0)
                                }
                                .shadow(color: .black.opacity(0.2), radius: 3.0, x: 0.0, y: 1.5)
                                .overlay {
                                    switch eventType {
                                    case .start:
                                        Image(systemName: "ipad.and.arrow.forward")
                                            .resizable()
                                            .foregroundStyle(.black)
                                            .fontWeight(.heavy)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 9.5)
                                            .offset(x: -1.0)
                                    case .breakStart:
                                        Image(systemName: "cup.and.heat.waves.fill")
                                            .resizable()
                                            .foregroundStyle(.black)
                                            .fontWeight(.heavy)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 9.5)
                                    case .end:
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .resizable()
                                            .foregroundStyle(.black)
                                            .fontWeight(.heavy)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 9.5)
                                            .offset(x: 1.0)
                                    default: Color.clear
                                    }
                                }
//                            Capsule(style: .continuous)
//                                .foregroundStyle(.white)
//                                .overlay {
//                                    Capsule(style: .continuous)
//                                        .stroke(.gray, lineWidth: 2.0)
//                                }
//                                .frame(width: 16.0, height: 6.0)
//                                .shadow(color: .black.opacity(0.2), radius: 3.0, x: 0.0, y: 1.5)
                        default: Color.clear
                        }
                    }
            }
            .layoutPriority(1.5)
            Group {
                switch eventType {
                case .start:
                    Text("Clock In Time")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                case .neutral:
                    Color.clear
                case .breakStart:
                    Text("Break Started")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                case .breakTime:
                    Color.clear
                case .breakEnd:
                    Text("Break Ended")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                case .end:
                    Text("Clock Out Time")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .layoutPriority(1.0)
            switch eventType {
            case .start, .breakStart, .breakEnd, .end:
                Spacer(minLength: 0.0)
                Group {
                    if let validDateRanges {
                        DatePicker(
                            "",
                            selection: $date,
                            in: validDateRanges,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } else {
                        DatePicker(
                            "",
                            selection: $date,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                .frame(minHeight: 50.0)
                .layoutPriority(0.5)
            default:
                Spacer(minLength: 0.0)
            }
        }
        .padding(.leading, 24.0)
        .padding(.trailing, 20.0)
        .listRowInsets(.init(top: 0.0, leading: 0.0, bottom: 0.0, trailing: 0.0))
        .listRowSeparator(.hidden)
    }

    enum EventType {
        case start
        case neutral
        case breakStart
        case breakTime
        case breakEnd
        case end
    }

    var lineStyle: any ShapeStyle {
        switch eventType {
        case .start:
            return LinearGradient(
                stops: [.init(color: .clear, location: 0.0),
                        .init(color: .accent, location: 0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .neutral:
            return Color.accent
        case .breakStart:
            return LinearGradient(
                stops: [.init(color: .accent, location: 0.0),
                        .init(color: .pink, location: 0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .breakTime:
            return Color.pink
        case .breakEnd:
            return LinearGradient(
                stops: [.init(color: .pink, location: 0.4),
                        .init(color: .accent, location: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .end:
            return LinearGradient(
                stops: [.init(color: .accent, location: 0.4),
                        .init(color: .clear, location: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

#Preview {
    List {
        TimelineRow(.start, date: .constant(.now))
        TimelineRow(.breakStart, date: .constant(.now))
        TimelineRow(.breakEnd, date: .constant(.now))
        TimelineRow(.neutral, date: .constant(.now))
        TimelineRow(.end, date: .constant(.now))
    }
    .listStyle(.plain)
    .listRowSpacing(0.0)
    .environment(\.defaultMinListRowHeight, 26.0)
}
