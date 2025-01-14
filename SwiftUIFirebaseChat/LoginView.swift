//
//  ContentView.swift
//  SwiftUIFirebaseChat
//
//  Created by DaiTran on 10/1/25.
//

import SwiftUI
import Firebase




struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginState = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var loginMessage: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var selectedImage: UIImage?
    

    
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
                            isImagePickerPresented.toggle()
                        }
                        label: {
                            if let selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(
                                        Circle()
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 4)
                                    )
                                    .shadow(
                                        radius: 10
                                    )
                                    .frame(
                                        width: 150,
                                        height: 150
                                    )
                                    .padding()
                            } else {
                                Image(systemName: "person.fill")
                                    .scaledToFit()
                                    .clipShape(
                                        Circle()
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 4)
                                    )
                                    .shadow(
                                        radius: 10
                                    )
                                    .font(.system(size: 150))
                                    .padding()
                                    .foregroundStyle(Color(.label))
                            }
                            
                        }
                        .sheet(isPresented: $isImagePickerPresented) {
                            ImagePicker(selectedImage: $selectedImage)
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
                        handleAction()
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
                    Text(self.loginMessage)
                        .foregroundStyle(.red)
                }
                .padding()

            }

            .navigationTitle(Text(isLoginState ? "Login Page" : "Signup Page"))
            .background(Color(UIColor(white: 0, alpha: 0.05)).ignoresSafeArea())
        }

    }
    private func handleAction() {
        if isLoginState {
            loginUser()
        } else {
            createNewAccount()
        }
    }
    private func loginUser() {
        FirebaseManager.shared.auth
            .signIn(withEmail: email, password: password) { result, error in
                if let error {
                    self.loginMessage = "Error login user: \(error)"
                    return
                }
                self.loginMessage = "Successfully logged in user \(self.email)"
            }
    }
    private func createNewAccount() {
        FirebaseManager.shared.auth
            .createUser(withEmail: email, password: password) { result, error in
                if let error {
                    print("Error creating user: \(error)")
                    self.loginMessage = "Error creating user: \(error)"
                    return
                }
                print("Successfully created user \(result?.user.uid ?? "")")
                self.loginMessage = "Successfully created user \(self.email)"
                
                storeUserInformation()
            }
    }
    
    private func storeUserInformation() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = ["email": self.email, "uid": uid]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { error in
                if let error = error {
                    print(error)
                    self.loginMessage = "Failed to store user information \(error)"
                    return
                }
            }
    }
    
    private func persistImageToStorage() {
       
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.selectedImage?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metadate, error in
            if let error = error {
                self.loginMessage = "Failed to upload image \(error)"
                return
            }
        }
        ref.downloadURL() { url, error in
            if let error = error {
                self.loginMessage = "Failed to retrieve download url \(error)"
                return
            }
            
            self.loginMessage = "Successfully uploaded image to storage and retrieved download url \(url?.absoluteString ?? "")"
        }
       
    }
}

#Preview {
    LoginView(didCompleteLoginProcess: {
        
    })
}
