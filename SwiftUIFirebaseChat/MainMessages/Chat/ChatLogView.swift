//
//  ChatLogView.swift
//  SwiftUIFirebaseChat
//
//  Created by DaiTran on 13/1/25.
//

import SwiftUI
import Firebase

struct RecentMessage: Identifiable {
    var id: String {documentId}
    
    let documentId, text, fromId, toId, email : String
    let timestamp: Timestamp
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.email = data[FirebaseConstants.email] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.timestamp = data[FirebaseConstants.timestamp] as? Timestamp ?? Timestamp(date: Date())
    }
    
}

struct FirebaseConstants {
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timestamp = "timestamp"
    static let email = "email"
}
struct ChatMessage : Identifiable {
    var id : String {documentId}
    let documentId,fromId, toId, text: String
    init(documentId:String, data: [String: Any]){
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var chatUser: ChatUser?
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var count = 0
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
        
    }
    func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {
            return
        }
        guard let toId = self.chatUser?.uuid else {return}
        
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, err in
                if let err {
                    self.errorMessage = "fail to fetch messages \(err)"
                    print(err)
                    return
                } else {
                    
                    querySnapshot?.documentChanges.forEach({ change in
                        if change.type == .added{
                            let data = change.document.data()
                            let docId = change.document.documentID
                            self.chatMessages
                                .append(.init(documentId: docId, data: data))
                            
                        }
                    })
                    DispatchQueue.main.async {
                        self.count += 1
                    }
                    
                }
            }
    }
    func handleSend() {
        print(chatText)
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {
            return
        }
        guard let toId = self.chatUser?.uuid else {return}
        
        let document = FirebaseManager.shared.firestore.collection("messages")
            .document(fromId).collection(toId).document()
        let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: self.chatText, FirebaseConstants.timestamp: Timestamp()] as [String: Any]
        
        document.setData(messageData) { err in
            if let err {
                self.errorMessage = "fail to stored sent message \(err)"
                return
            } else {
                print("successfully stored sent message")
                self.persistRecentMessage()
                self.chatText = ""
                self.count += 1
            }
            
            
        }
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection(
            "messages"
        )
            .document(toId).collection(fromId).document()
        
        recipientMessageDocument.setData(messageData) { err in
            if let err {
                self.errorMessage = "fail to stored sent message \(err)"
                return
            } else {
                print("Recipient successfully stored sent message")
            }
        }
            
    }
    private func persistRecentMessage() {
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uuid else { return }
        let document = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        let data = [
            FirebaseConstants.timestamp : Timestamp(),
            FirebaseConstants.text :  self.chatText,
            FirebaseConstants.fromId : uid,
            FirebaseConstants.toId : toId,
            FirebaseConstants.email : self.chatUser?.email ?? "",
            
        ] as [String : Any]
        
        document.setData(data) { err in
            if let err {
                self.errorMessage = "Fail to fetch recent messages \(err)"
                print("Fail to fetch recent messages \(err)")
                return
            }
        }
    }
}

struct ChatLogView: View {
    let chatUser: ChatUser?
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = ChatLogViewModel(chatUser: chatUser)
    }
    @ObservedObject var vm : ChatLogViewModel
    var body: some View {
        VStack {
                
            messagesView
            chatBottomBar
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
        .navigationTitle("\(chatUser?.email ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        
        
    }
    private var messagesView: some View {
        ScrollView {
            ScrollViewReader {
                scrollViewProxy in
                VStack {
                    ForEach(vm.chatMessages) { message in
                        MessageView(message: message)
                    }
                    HStack {Spacer()}
                        .id("Empty")
                }
                .onReceive(vm.$count) { _ in
                    withAnimation(.easeOut(duration: 0.5)) {
                        scrollViewProxy
                            .scrollTo("Empty", anchor: .bottom)                        
                    }
                }
            }
        }
    }

    private var  chatBottomBar: some View {
        HStack {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundStyle(Color(.darkGray))
            
            ZStack {
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
            }.frame(height: 40)
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)
            .padding(.vertical,8)
            .background(Color.blue)
            .cornerRadius(8)

        }.padding()
            
    }
}
struct MessageView : View {
    let message: ChatMessage
    var body: some View {
        VStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }.padding(.horizontal)
                    .padding(.top,8)
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundStyle(Color(.black))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    Spacer()
                }.padding(.horizontal)
                    .padding(.top,8)
            }
        }
    }
}

#Preview {
    NavigationView {
        ChatLogView(
            chatUser: .init(
                data: [
                    "uid": "a1e2UL5HwFb11A1nDNcrVwqfCPx2",
                    "email": "Tranphuc@mail.com"
                ]
            )
        )
    }

}
