//
//  Logger.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2026/02/08.
//

import os
import Foundation

let logger = Logger()

func log(_ message: String, prefix: String = "NOA") {
    logger.warning("[\(prefix)] \(message)")
}
