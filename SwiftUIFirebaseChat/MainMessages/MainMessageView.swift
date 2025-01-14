//
//  MainMessageView.swift
//  SwiftUIFirebaseChat
//
//  Created by DaiTran on 11/1/25.
//

import SwiftUI

class MainMessageViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var chatUser : ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
    @Published var recentMessages = [RecentMessage]()
    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
        fetchRecentMessages()
    }
     func fetchRecentMessages() {
         guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
         
         let document = FirebaseManager.shared.firestore
             .collection("recent_messages")
             .document(uid)
             .collection("messages")
             .order(by: "timestamp")
             .addSnapshotListener { querySnapshot, err in
                 if let err {
                     print(err)
                     return
                 } else {
                     querySnapshot?.documentChanges.forEach({ change in
                             let docId = change.document.documentID
                         if let index = self.recentMessages.firstIndex(where: { rm in
                             return rm.documentId == docId
                         }) {
                             self.recentMessages.remove(at: index)
                         }
                             let data = change.document.data()
                         self.recentMessages.insert(.init(documentId: docId, data: data), at: 0)
                     })
                 }
             }
           
    }
     func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            return
        }
        self.errorMessage = "\(uid) data"
        FirebaseManager.shared.firestore
            .collection("users")
            .document(uid)
            .getDocument { snapshot, error in
                if let error {
                    print("Faild to fetch current user",error)
                    return
                }
            
                guard let data = snapshot?.data() else { return }
                self.chatUser = .init(data: data)
            
            }
    }
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
        
    }
}

struct MainMessageView: View {
    
    @State var showLogOutOptions: Bool = false
    @ObservedObject private var vm = MainMessageViewModel()
    @State var showNewMessagesScreen: Bool = false
    @State var chatUser: ChatUser?
    @State var navigateToChatLogView: Bool = false
    var body: some View {
        NavigationView {
            VStack {
               
                customNavBar
                    
                messagesView
                
                NavigationLink("",isActive:$navigateToChatLogView) {
                    ChatLogView(chatUser: chatUser)
                }
               
            }
            .overlay (
                newMessageButton
                ,alignment: .bottom)
            
            .navigationBarBackButtonHidden(true)
        }
        
    }
    
    private var customNavBar : some View {
        HStack {
            HStack(spacing: 16) {
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading,spacing: 4) {
                    let email = vm.chatUser?.email.replacingOccurrences(
                        of: "@mail.com",
                        with: ""
                    ) ?? ""
                    Text(email)
                    HStack {
                        Circle()
                            .foregroundStyle(.green)
                            .frame(width: 10)
                        Text("online")
                            .foregroundStyle(Color(.lightGray))
                            .font(.system(size: 14))
                    }
                }
            }
            Spacer()
            Button {
                showLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24,weight: .bold))
                    .foregroundStyle(Color(.label))
            }
            
        }
        .padding()
        .actionSheet(isPresented: $showLogOutOptions) {
            .init(title: Text("Settings"),message: Text("What do you want to do?"),buttons: [.destructive(Text("Sign Out"),action: {
                print("Handle sign out")
                vm.handleSignOut()
            }),.cancel()])
        }
        .fullScreenCover(
            isPresented: $vm.isUserCurrentlyLoggedOut,
            onDismiss: nil
        ) {
            LoginView(didCompleteLoginProcess: {
                
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
            })
        }
    }
    private var newMessageButton : some View {
        Button {
            showNewMessagesScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16,weight:.semibold))
                Spacer()
            }
            
            .foregroundStyle(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $showNewMessagesScreen, onDismiss: nil) {
            NewMessageView(didSelectNewUser: { user in
                self.chatUser = user
                self.navigateToChatLogView.toggle()
            })
        }
    }
    private var messagesView : some View {
        ScrollView {
            ForEach(vm.recentMessages) { recentMessage in
                VStack {
                    NavigationLink {
                        Text("New message")
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color(.label))
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 44)
                                        .stroke(Color(.label),lineWidth: 1)
                                )
                            VStack(alignment: .leading) {
                                Text(recentMessage.email)
                                    .font(
                                        .system(size: 16,weight: .semibold)
                                    )
                                    .foregroundStyle(Color(.label))
                                Text(recentMessage.text)
                                    .foregroundStyle(Color(.label))
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.leading    )
                            }
                            Spacer()
                            Text("22d")
                                .font(.system(size: 14,weight: .semibold))
                                .foregroundStyle(Color(.label))
                        }
                    }

                   
                    Divider()
                        .padding(.vertical,8)
                }.padding(.horizontal)
            }.padding(.bottom, 50)
        }
    }
    
}


#Preview {
    
    MainMessageView()
        
    
}
