//
//  ChatUser.swift
//  SwiftUIFirebaseChat
//
//  Created by DaiTran on 11/1/25.
//

import Foundation
struct ChatUser: Identifiable {
    var id: String { uuid }
    let uuid,email: String
    
    init(data: [String:Any]) {
        self.uuid  = data["uid"] as? String ?? ""
        self.email  = data["email"] as? String ?? ""
    }
}
