//
//  LoginView.swift
//  calendar
//
//  Created by Atsushi Nakatsugawa on 2022/11/21.
//

import SwiftUI
import NCMB

struct LoginView: View {
    // 入力用
    @State private var userName: String = ""
    @State private var password: String = ""
    // レスポンス用
    @Binding var isLogin: Bool

    var body: some View {
        VStack(spacing: 16) {
            TextField("ユーザ名", text: $userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 280)
            SecureField("パスワード", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 280)
            Button(action: {
                _signUpOrLogin()
            }, label: {
                Text("新規登録/ログイン")
            })
        }
    }
    
    // ユーザー登録またはログインを行う処理
    func _signUpOrLogin() -> Void {
        // ユーザ登録処理
        let user = NCMBUser()
        user.userName = userName
        user.password = password
        user.signUpInBackground(callback: { _ in
            // 成功しても失敗してもそのままログイン処理
            NCMBUser.logInInBackground(userName: userName, password: password, callback: { _ in
                // ログイン結果を反映
                isLogin = NCMBUser.currentUser != nil
            })
        })
    }
}

struct LoginView_Previews: PreviewProvider {
    @State static var isLogin = false
    
    static var previews: some View {
        LoginView(isLogin: $isLogin)
    }
}
