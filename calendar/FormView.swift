//
//  FormView.swift
//  calendar
//
//  Created by Atsushi Nakatsugawa on 2022/11/21.
//

import SwiftUI
import NCMB

// 予定の入力・更新画面
struct FormView: View {
    // 一覧から受け取った予定
    @Binding var schedule: NCMBObject
    // 作成・更新用フラグ
    @Binding var updated: Bool
    // 削除用のオブジェクトIDを入れる
    @Binding var deleteObjectId: String
    
    @Environment(\.presentationMode) var presentation
    // 入力用
    @State private var _title: String = ""
    @State private var _body: String = ""
    @State private var _startDate: Date = Date.now
    @State private var _endDate: Date = Date.now
    
    // スケジュールデータを入力用に適用される処理
    func _setValue() -> Void {
        _title = schedule["title"] ?? ""
        _body = schedule["body"] ?? ""
        // 新規データの場合は nil なので、判別してからセット
        if let startDateValue = schedule["startDate"] as Any? {
            _startDate = startDateValue as! Date
        }
        if let endDateValue = schedule["startDate"] as Any? {
            _endDate = endDateValue as! Date
        }
    }
    
    // 開始日が変更されたら、それに合わせて終了日を自動設定
    func _setEndDate() -> Void {
        var params = Calendar.current.dateComponents([.calendar, .year, .month, .day, .hour, .minute], from: _startDate)
        params.hour! += 1 // 1時間後にする
        _endDate = params.date!
    }
    
    // スケジュールの保存処理
    func _save() -> Void {
        // 入力値を設定
        schedule["title"] = _title
        schedule["body"] = _body
        schedule["startDate"] = _startDate
        schedule["endDate"] = _endDate
        // ACL（アクセス権限）を設定
        var acl = NCMBACL.empty
        let user = NCMBUser.currentUser
        acl.put(key: user!.objectId!, readable: true, writable: true)
        schedule.acl = acl
        // 保存実行
        schedule.saveInBackground(callback: { result in
            // 保存が成功していれば、更新フラグを立てる
            if case .success(_) = result {
                DispatchQueue.main.async {
                    updated = true
                    presentation.wrappedValue.dismiss()
                }
            }
        })
    }
    // 予定の削除処理
    func _delete() -> Void {
        // 削除すると nil になるので、その前に保存
        let objectId = schedule.objectId!
        // 削除実行
        schedule.deleteInBackground(callback: {result in
            if case .success(_) = result {
                DispatchQueue.main.async {
                    // フラグを立てる
                    deleteObjectId = objectId
                    presentation.wrappedValue.dismiss()
                }
            }
        })
    }
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("予定のタイトル", text: $_title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            DatePicker("開始日時", selection: $_startDate)
                .padding(.horizontal, 20)
            DatePicker("終了日時", selection: $_endDate)
                .padding(.horizontal, 20)
            TextEditor(text: $_body)
                .frame(maxWidth: .infinity, maxHeight: 300)
                .border(.gray)
                .padding(.horizontal, 20)
            Button(action: {
                _save()
            }, label: {
                Text("新規保存 or 更新")
            })
            _schedule.wrappedValue.objectId != nil ?
            Button(action: {
                _delete()
            }, label: {
                Text("予定の削除")
            }) : nil
        // 開始日が変更された際のイベント
        }.onChange(of: _startDate, perform: {(_) in
            _setEndDate()
        })
        // 表示された際のイベント
        .onAppear {
            _setValue()
        }
    }
}

struct FormView_Previews: PreviewProvider {
    static var bol: Bool = false
    static func getSchedule() -> NCMBObject {
        let schedule = NCMBObject.init(className: "Schedule")
        schedule["startDate"] = Date.now
        schedule["endDate"] = Date.now
        schedule["title"] = "テストスケジュール"
        schedule["body"] = "これはテストのスケジュールです。これはテストのスケジュールです。"
        return schedule
    }

    static var previews: some View {
        FormView(schedule: Binding.constant(getSchedule()), updated: Binding.constant(bol), deleteObjectId: Binding.constant(""))
    }
}
