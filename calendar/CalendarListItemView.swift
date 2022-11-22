//
//  CalendarListItemView.swift
//  calendar
//
//  Created by Atsushi Nakatsugawa on 2022/11/21.
//

import SwiftUI
import NCMB

// 予定の一覧用（行）
struct CalendarListItemView: View {
    @State var schedule: NCMBObject
    // 時間を表示する文字列を返す
    func _viewTime() -> String {
        let startDate = schedule["startDate"]! as Date
        let endDate = schedule["endDate"]! as Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return "\(dateFormatter.string(from: startDate))〜\(dateFormatter.string(from: endDate))"
    }
    // 描画
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(schedule["title"]! as String)
                    .fontWeight(.bold)
                    .font(.title3)
                    .padding(.leading, 20)
                Spacer()
                Text(_viewTime())
                    .frame(alignment: .trailing)
                    .font(.caption)
                    .padding(.trailing, 20)
            }
            Text(schedule["body"]! as String)
                .padding(.horizontal, 20)
                .padding(.top, 5)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
    }
}


struct CalendarListItemView_Previews: PreviewProvider {
    static func getSchedule() -> NCMBObject {
        let schedule = NCMBObject.init(className: "Schedule")
        schedule["startDate"] = Date.now
        schedule["endDate"] = Date.now
        schedule["title"] = "テストスケジュール"
        schedule["body"] = "これはテストのスケジュールです。これはテストのスケジュールです。"
        return schedule
    }
    
    static var previews: some View {
        CalendarListItemView(schedule: getSchedule())
    }
}
