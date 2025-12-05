//
//  AppDelegate.swift
//  SimpleArchive
//
//  Created by Nicode . on 6/19/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool { true }

    func application(
        _ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}

extension AppDelegate {
    static func prettyPrint(
        _ message: Any = "called",
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {

        let info = " \(file):\(line) \(function) "
        let startLine = "🍩🍪🍰🍩🍪🍰🍩🍪🍰🍩🍪🍰\(info)🍩🍪🍰🍩🍪🍰🍩🍪🍰🍩🍪🍰"
        let endLine =
            String(repeating: "🧁🍨🍮", count: 8) + String(repeating: "🧁🍨🍮", count: info.count / 6)

        print(
            """

            \(startLine)
            \(message)
            \(endLine)

            """
        )
    }
}
