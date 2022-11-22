//
//  calendarApp.swift
//  calendar
//
//  Created by Atsushi Nakatsugawa on 2022/11/21.
//

import SwiftUI
import NCMB

@main
struct calendarApp: App {
    init() {
        // NCMBの初期化
        NCMB.initialize(applicationKey: "9170ffcb91da1bbe0eff808a967e12ce081ae9e3262ad3e5c3cac0d9e54ad941", clientKey: "9e5014cd2d76a73b4596deffdc6ec4028cfc1373529325f8e71b7a6ed553157d")
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
