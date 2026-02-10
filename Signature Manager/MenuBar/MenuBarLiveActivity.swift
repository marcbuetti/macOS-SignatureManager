//
//  MenuBarLiveActivity.swift
//  Signature Manager
//
//  Created by Marc Büttner on 05.09.25.
//

import SwiftUI


final class MenuBarLiveActivity: ObservableObject {
    @Published var showLiveActivity: Bool = false
    @Published var progress: Double = 0.0
    @Published var status: MenuBarStatus = .ok

    func setOK()       { status = .ok }
    func setUpdating() { status = .updating }
    func setError()    { status = .error }
}

