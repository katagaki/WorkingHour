//
//  UshioBundle.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2024/12/09.
//

import WidgetKit
import SwiftUI

@main
struct UshioBundle: WidgetBundle {
    var body: some Widget {
        Ushio()
        StartWorkSessionControl()
        EndWorkSessionControl()
        UshioLiveActivity()
    }
}
