import XCTest

final class BrowserCaptureTests: XCTestCase {
    func testSafariCaptureFormatterConvertsReadableHTMLToMarkdown() throws {
        let payload = BrowserCapturePayload(
            title: "Example Article",
            url: "https://example.com/articles/one",
            text: "Fallback text that should not win.",
            html: """
            <article>
              <h1>Example Article</h1>
              <p>Speak <strong>boldly</strong> and <em>clearly</em>.</p>
              <ul><li>First point</li><li>Second point</li></ul>
            </article>
            """,
            captureMode: "article",
            capturedAt: "2026-06-28T12:00:00.000Z"
        )

        let markdown = try BrowserCaptureFormatter.speechMarkdown(from: payload)

        XCTAssertTrue(markdown.contains("# Example Article"))
        XCTAssertTrue(markdown.contains("Speak **boldly** and *clearly*."))
        XCTAssertTrue(markdown.contains("- First point"))
        XCTAssertTrue(markdown.contains("- Second point"))
        XCTAssertFalse(markdown.contains("Fallback text that should not win."))
    }

    func testSafariCaptureFormatterFallsBackToVisibleTextWhenHTMLIsEmpty() throws {
        let payload = BrowserCapturePayload(
            title: "Fallback",
            url: "https://example.com",
            text: "  Use   visible\ntext. ",
            html: " \n\t ",
            captureMode: "body",
            capturedAt: "2026-06-28T12:00:00.000Z"
        )

        XCTAssertEqual(try BrowserCaptureFormatter.speechMarkdown(from: payload), "Use visible text.")
    }

    func testSafariCaptureFormatterRejectsEmptyPageCapture() {
        let payload = BrowserCapturePayload(
            title: "Empty",
            url: "https://example.com",
            text: " \n\t ",
            html: "<script>hidden()</script>",
            captureMode: "body",
            capturedAt: "2026-06-28T12:00:00.000Z"
        )

        XCTAssertThrowsError(try BrowserCaptureFormatter.speechMarkdown(from: payload)) { error in
            guard case BrowserCaptureError.emptyCapture = error else {
                return XCTFail("Expected emptyCapture, got \(error).")
            }
        }
    }

    func testSafariBrowserSpeechRequestEncodesLeanContext() throws {
        let request = BrowserSpeechRequest(
            text: "# Example Article\n\nSpeak this.",
            requestContext: .init(
                source: "Safari",
                topic: "Example Article",
                attributes: .init(
                    surface: "browser_extension",
                    browserName: "Safari",
                    browserURL: "https://example.com/articles/one",
                    captureMode: "article",
                    capturedAt: "2026-06-28T12:00:00.000Z"
                ),
                prefacePolicy: nil
            )
        )

        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        let context = object?["request_context"] as? [String: Any]
        let attributes = context?["attributes"] as? [String: Any]

        XCTAssertEqual(object?["text"] as? String, "# Example Article\n\nSpeak this.")
        XCTAssertEqual(context?["source"] as? String, "Safari")
        XCTAssertEqual(context?["topic"] as? String, "Example Article")
        XCTAssertNil(context?["prefacePolicy"])
        XCTAssertEqual(attributes?["surface"] as? String, "browser_extension")
        XCTAssertEqual(attributes?["browser.name"] as? String, "Safari")
        XCTAssertEqual(attributes?["browser.url"] as? String, "https://example.com/articles/one")
        XCTAssertEqual(attributes?["browser.capture_mode"] as? String, "article")
        XCTAssertEqual(attributes?["browser.captured_at"] as? String, "2026-06-28T12:00:00.000Z")
        XCTAssertNil(attributes?["html"])
        XCTAssertNil(attributes?["text"])
        XCTAssertNil(attributes?["browser.html"])
        XCTAssertNil(attributes?["browser.text"])
    }
}
