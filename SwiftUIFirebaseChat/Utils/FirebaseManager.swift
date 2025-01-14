//
//  File.swift
//  SwiftUIFirebaseChat
//
//  Created by DaiTran on 11/1/25.
//

import Foundation
import Firebase

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class FirebaseManager: NSObject {
    static let shared = FirebaseManager()
    
    let auth: Auth
    
    let storage: Storage
    
    let firestore: Firestore
    
    private override init() {
        FirebaseApp.configure()
        
        auth = Auth.auth()
        
        storage = Storage.storage()
        
        firestore = Firestore.firestore()
    
        super.init()
    }
}
