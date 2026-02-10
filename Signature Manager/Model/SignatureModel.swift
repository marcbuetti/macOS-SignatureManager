//
//  Signature.swift
//  Signature Manager
//
//  Created by Marc Büttner on 31.01.26.
//

import SwiftData
import SwiftUI

@Model
final class Signature {
    @Attribute(.unique) var uuid: UUID
    var mailSignatureId: String
    var name: String
    var htmlPath: String
    var storageType: StorageType
    var m365FileName: String?
    var lastUpdated: Date

    init(
        mailSignatureId: String,
        name: String,
        htmlPath: String,
        storageType: StorageType,
        m365FileName: String? = nil,
        lastUpdated: Date = .now
    ) {
        self.uuid = UUID()
        self.mailSignatureId = mailSignatureId
        self.name = name
        self.htmlPath = htmlPath
        self.storageType = storageType
        self.m365FileName = m365FileName
        self.lastUpdated = lastUpdated
    }
}

enum StorageType: String, Codable {
    case local
    case cloudM365
}
