import Foundation
import SwiftSoup

enum BrowserCaptureFormatter {
    private static let maximumQueuedCharacterCount = 60000

    static func speechMarkdown(from payload: BrowserCapturePayload) throws -> String {
        let markdown = try markdownFromHTML(payload.html, baseURL: payload.url)
        let fallback = normalizedWhitespace(payload.text)
        let text = markdown.isEmpty ? fallback : markdown

        guard !text.isEmpty else {
            throw BrowserCaptureError.emptyCapture
        }

        return String(text.prefix(maximumQueuedCharacterCount))
    }

    private static func markdownFromHTML(_ html: String, baseURL: String) throws -> String {
        guard !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ""
        }

        let document = try SwiftSoup.parseBodyFragment(html, baseURL)
        guard let body = document.body() else {
            return ""
        }

        return normalizedMarkdown(renderChildren(of: body, listDepth: 0))
    }

    private static func renderChildren(of node: Node, listDepth: Int) -> String {
        node.childNodesCopy()
            .map { render($0, listDepth: listDepth) }
            .joined()
    }

    private static func render(_ node: Node, listDepth: Int) -> String {
        if let textNode = node as? TextNode {
            return normalizedInline(textNode.text())
        }

        guard let element = node as? Element else {
            return renderChildren(of: node, listDepth: listDepth)
        }

        let tagName = element.tagNameNormal()
        let childText = renderChildren(of: element, listDepth: listDepth)

        switch tagName {
            case "h1":
                return block("# \(plainText(childText))")
            case "h2":
                return block("## \(plainText(childText))")
            case "h3":
                return block("### \(plainText(childText))")
            case "h4":
                return block("#### \(plainText(childText))")
            case "h5":
                return block("##### \(plainText(childText))")
            case "h6":
                return block("###### \(plainText(childText))")
            case "p", "article", "aside", "div", "footer", "header", "main", "nav", "section":
                return block(childText)
            case "br":
                return "\n"
            case "ul", "ol":
                return "\n\(renderChildren(of: element, listDepth: listDepth + 1))\n"
            case "li":
                let indent = String(repeating: "  ", count: max(0, listDepth - 1))
                return "\(indent)- \(plainText(childText))\n"
            case "blockquote":
                return block(plainText(childText)
                    .split(separator: "\n")
                    .map { "> \($0)" }
                    .joined(separator: "\n"))
            case "pre":
                return block("```\n\(plainText(childText))\n```")
            case "code":
                return "`\(plainText(childText))`"
            case "strong", "b":
                return "**\(plainText(childText))**"
            case "em", "i":
                return "*\(plainText(childText))*"
            case "script", "style", "noscript", "template", "svg":
                return ""
            default:
                return childText
        }
    }

    private static func block(_ text: String) -> String {
        let normalized = normalizedMarkdown(text)
        return normalized.isEmpty ? "" : "\n\(normalized)\n\n"
    }

    private static func plainText(_ text: String) -> String {
        normalizedWhitespace(text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "*", with: ""))
    }

    private static func normalizedInline(_ text: String) -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ""
        }

        return text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    private static func normalizedWhitespace(_ text: String) -> String {
        text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizedMarkdown(_ text: String) -> String {
        text.replacingOccurrences(of: #"[ \t]+\n"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum BrowserCaptureError: LocalizedError {
    case emptyCapture
    case invalidMessage
    case queueFailed(Int, String)

    var errorDescription: String? {
        switch self {
            case .emptyCapture:
                "SayBar could not queue the browser capture because the page did not contain speakable text."
            case .invalidMessage:
                "SayBar could not read the Safari Web Extension message because it did not contain the expected page capture payload."
            case let .queueFailed(statusCode, body):
                "SayBar could not queue the browser capture because the embedded runtime returned HTTP \(statusCode). Likely cause: \(body)"
        }
    }
}
