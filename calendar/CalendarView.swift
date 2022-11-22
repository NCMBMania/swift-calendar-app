//
//  CalendarView.swift
//  calendar
//
//  Created by Atsushi Nakatsugawa on 2022/11/21.
//

import SwiftUI
import FSCalendar
import UIKit
import NCMB

// カレンダー用の構造体
class DayData: ObservableObject {
    @Published var schedules: [NCMBObject] = []
    @Published var selectedDate = Date()
    @Published var currentYearMonth = Date()
}


struct CalendarView: View {
    @ObservedObject var dayData = DayData()
    // 作成・更新した際のフラグ
    @State private var updated = false
    // 削除されたオブジェクトIDを入れる
    @State private var deleteObjectId = ""
    // 作成したスケジュールが入るNCMBObject
    @State private var schedule: NCMBObject = NCMBObject(className: "Schedule")
    
    // 予定をNCMBのデータストアから取得する関数
    func _getSchedule() {
        // 対象となるクラス（DBで言うテーブル名相当）
        var query = NCMBQuery.getQuery(className: "Schedule")
        // 1日00時00分
        var startDate = Calendar.current.dateComponents([.calendar, .year, .month, .day], from: dayData.currentYearMonth)
        startDate.day = 1
        // 翌月1日00時00分
        var endDate = Calendar.current.dateComponents([.calendar, .year, .month, .day], from: startDate.date!)
        endDate.month! += 1
        endDate.day = 1
        // 検索条件設定
        query.where(field: "startDate", greaterThanOrEqualTo: startDate.date!)
        query.where(field: "endDate", lessThan: endDate.date!)
        query.limit = 1000
        // 検索実行
        query.findInBackground(callback: {results in
            if case let .success(ary) = results {
                // 結果を適用
                DispatchQueue.main.async {
                    dayData.schedules = ary;
                }
            }
        })
    }
    
    // 一覧のタイトル用
    func _viewTitle() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日"
        return dateFormatter.string(from: dayData.selectedDate)
    }
    
    // 該当日のスケジュールだけを返す関数
    func _dateFilter() -> [NCMBObject] {
        // 該当日の0時00分
        let startDateComponent = Calendar.current.dateComponents([.calendar, .year, .month, .day], from: dayData.selectedDate)
        // 該当日の23時59分
        var endDateComponent = Calendar.current.dateComponents([.calendar, .year, .month, .day], from: dayData.selectedDate)
        endDateComponent.minute = -1
        endDateComponent.day! += 1
        
        return dayData.schedules.filter({ (schedule) in
            // データ削除対策用
            if schedule.objectId == nil {
                return false
            }
            // 予定の開始日時・終了日時を取得
            let startDate = schedule["startDate"]! as Date
            let endDate = schedule["endDate"]! as Date
            //予定の開始日時・終了日時が範囲に収まっているか判定
            return startDateComponent.date! <= startDate && endDateComponent.date! > endDate
        })
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // カレンダービュー
                FSCalendarView(dayData: Binding.constant(dayData))
                    .frame(height: 400)
                    .onChange(of: dayData.currentYearMonth, perform: {(newValue) in
                        // 表示月が変わったら、予定を取得し直す
                        _getSchedule()
                    })
                Text(_viewTitle())
                    .font(.title)
                    .padding()
                // 選択した日の予定を一覧表示
                List(_dateFilter(), id: \.objectId) { schedule in
                    // 一覧をタップしたら、編集画面に遷移
                    NavigationLink(destination: FormView(schedule: Binding.constant(schedule), updated: $updated, deleteObjectId: $deleteObjectId)) {
                        // 一覧表示用
                        CalendarListItemView(schedule: schedule)
                    }
                }
                Spacer()
            }
            .navigationTitle("カレンダー")
            // ナビゲーションバーのプラスアイコン
            .navigationBarItems(trailing:
                                    NavigationLink(destination: FormView(schedule: $schedule, updated: $updated, deleteObjectId: $deleteObjectId), label: {
                    Image(systemName: "plus")
                })
            )
            // 予定を追加、更新した際のイベント
            .onChange(of: updated, perform: {_ in
                if updated {
                    // 予定を追加
                    if schedule.objectId != nil {
                        dayData.schedules.append(schedule)
                        schedule = NCMBObject(className: "Schedule")
                    }
                    // フラグを落とす
                    updated = false
                }
            })
            // 予定を削除された際のイベント
            .onChange(of: deleteObjectId, perform: {_ in
                if deleteObjectId != "" {
                    // 予定データから削除された予定を削除
                    dayData.schedules.removeAll(where: {
                        $0.objectId == deleteObjectId
                    })
                    // 削除されたオブジェクトIDをリセット
                    deleteObjectId = ""
                }
            })
        }
        // 表示された際にスケジュールを取得する
        .onAppear {
            _getSchedule()
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}

// カレンダービュー
struct FSCalendarView: UIViewRepresentable {
    @Binding var dayData: DayData
    func makeUIView(context: Context) -> FSCalendar {
        typealias UIViewType = FSCalendar
        let fsCalendar = FSCalendar()
        fsCalendar.delegate = context.coordinator
        fsCalendar.dataSource = context.coordinator
        fsCalendar.appearance.headerDateFormat = "yyyy年MM月"
        
        return fsCalendar
    }
    // 再描画用
    func updateUIView(_ uiView: FSCalendar, context: Context) {
        uiView.reloadData()
    }
    
    func makeCoordinator() -> Coordinator{
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
        var parent: FSCalendarView
        
        init(_ parent: FSCalendarView){
            self.parent = parent
        }
        
        // 予定がある日付にドットを表示する処理
        func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
            // データがない場合は0を返して終わり
            if (parent.dayData.schedules.isEmpty) {
                return 0;
            }
            // 該当日のデータだけを抽出
            let events: [NCMBObject] = parent.dayData.schedules.filter({(obj) in
                if obj.objectId == nil {
                    return false
                }
                let startDate = obj["startDate"]! as Date
                let targetDate = Calendar.current.dateComponents([.calendar, .year, .month, .day], from: startDate).date
                return date.compare(targetDate!) == .orderedSame
            })
            // 該当日のカウントを返す
            return events.count
        }
        
        // 日付を選択した際の処理
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            parent.dayData.selectedDate = date
          
        }
        
        // 年月を変更した際の処理
        func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
            parent.dayData.currentYearMonth = calendar.currentPage
        }
        
    }
}
