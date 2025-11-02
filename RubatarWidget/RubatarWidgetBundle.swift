//
//  RubatarWidgetBundle.swift
//  RubatarWidget
//
//  Created by Meghdad Abbaszadegan on 11/1/25.
//

import WidgetKit
import SwiftUI

@main
struct RubatarWidgetBundle: WidgetBundle {
    var body: some Widget {
        RubatarWidget()
        RubatarWidgetControl()
        RubatarWidgetLiveActivity()
    }
}
