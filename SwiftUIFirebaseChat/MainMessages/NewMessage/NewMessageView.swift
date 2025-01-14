//
//  NewMessageView.swift
//  SwiftUIFirebaseChat
//
//  Created by DaiTran on 12/1/25.
//

import SwiftUI

class NewMessageViewModel: ObservableObject {
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    init() {
        fetchAllUsers()
    }
    private func fetchAllUsers() {
        FirebaseManager.shared.firestore.collection("users").getDocuments { documentsSnapshot, error in
            if let error {
                self.errorMessage = "Fail to fetch users \(error)"
                print("Faild to fetch current user",error)
                return
            }
            self.errorMessage = "Successfully fetched users"
            documentsSnapshot?.documents.forEach({ snapshot in
                 let data = snapshot.data()
                let user = ChatUser(data: data)
                if user.uuid != FirebaseManager.shared.auth.currentUser?.uid {
                    self.users.append(.init(data: data))
                }
                
            })
        }
    }
}

struct NewMessageView: View {
    let didSelectNewUser: (ChatUser) -> ()
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm = NewMessageViewModel()
    var body: some View {
        NavigationView {
            ScrollView {                
                ForEach(vm.users) { user in
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 44)
                                        .stroke(Color(.label),lineWidth: 1)
                                )
                                .foregroundStyle(Color(.label))
                            let username = user.email.replacingOccurrences(of: "@mail.com", with: "")
                            Text("\(username)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(.label))
                            Spacer()
                        }.padding(.horizontal)
                        Divider()
                            .padding(.vertical,8)
                    }

                }
            
            }.navigationTitle("New Message")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel")
                        }

                    }
                }
        }
    }
}

#Preview {
    NewMessageView(didSelectNewUser: { user in
        
    })
}
