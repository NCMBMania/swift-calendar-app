//
//  ContentView.swift
//  calendar
//
//  Created by Atsushi Nakatsugawa on 2022/11/21.
//

import SwiftUI
import NCMB

struct ContentView: View {
    @State var isLogin: Bool = NCMBUser.currentUser != nil
    var body: some View {
        // ログイン判定
        if isLogin {
            // ログイン済みの場合
            CalendarView();
        } else {
            // 未ログインの場合
            LoginView(isLogin: $isLogin);
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
