//
//  TabType.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/11/04.
//

import Foundation
import Komponents

enum TabType: Int, TabTypeProtocol {
    case timesheet = 0
    case history = 1
    case projects = 2
    case export = 3
    case more = 4

    static var defaultTab: TabType = .timesheet
}
