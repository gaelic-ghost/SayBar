//
//  SafariWebExtensionHandler.swift
//  SayBarSafariExtension
//
//  Created by Gale Williams on 6/24/26.
//

import SafariServices

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let response = NSExtensionItem()
        response.userInfo = [
            SFExtensionMessageKey: [
                "ok": true,
                "nativeHandoff": "pending",
            ],
        ]

        context.completeRequest(returningItems: [response])
    }
}
