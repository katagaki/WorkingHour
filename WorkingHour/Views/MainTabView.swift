//
//  MainTabView.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/11/04.
//

import Komponents
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var navigator: Navigator<TabType, ViewPath>

    var body: some View {
        TabView(selection: $navigator.selectedTab) {
            Tab("Tab.TimeClock",
                systemImage: "deskclock.fill",
                value: .timesheet) {
                TimeClockView()
            }
            Tab("Tab.History",
                systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                value: .history) {
                TimesheetView()
            }
            Tab("Tab.Projects",
                systemImage: "folder.fill",
                value: .projects) {
                ProjectsView()
            }
            Tab("Tab.More",
                systemImage: "ellipsis",
                value: .more) {
                MoreView()
            }

        }
    }
}
