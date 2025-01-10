//
//  ContentView.swift
//  SwiftUIFirebaseChat
//
//  Created by DaiTran on 10/1/25.
//

import SwiftUI
import Firebase



struct LoginView: View {
   
    @State var isLoginState = false
    @State var email: String = ""
    @State var password: String = ""
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Picker(selection: $isLoginState) {
                        Text("Login")
                            .tag(true)
                        Text("Signup")
                            .tag(false)
                    } label: {
                        Text("Picker here")
                    }.pickerStyle(SegmentedPickerStyle())

                    if !isLoginState {
                        Button {

                        } label: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 64))
                                .padding()
                        }
                    }

                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.none)

                        SecureField("Password", text: $password)
                    }
                    .padding(12)
                    .background(.white)

                    Button {

                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginState ? "Log In" : "Create Account")
                                .foregroundStyle(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14,weight: .semibold))
                            Spacer()
                        }.background(.blue)

                    }
                }
                .padding()

            }

            .navigationTitle(Text(isLoginState ? "Login Page" : "Signup Page"))
            .background(Color(UIColor(white: 0, alpha: 0.05)).ignoresSafeArea())
        }

    }
}

#Preview {
    LoginView()
}
