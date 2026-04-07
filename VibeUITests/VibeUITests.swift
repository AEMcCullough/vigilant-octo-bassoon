import XCTest

final class VibeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchAndTitlePresence() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the VIBE title is visible
        let vibeStaticText = app.staticTexts["VIBE"]
        XCTAssertTrue(vibeStaticText.exists)
    }
    
    func testTouchInteraction() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Simulate a drag across the screen
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.8))
        start.press(forDuration: 0, thenDragTo: end)
        
        // App should continue running after interaction
        XCTAssertTrue(app.state == .runningForeground)
    }
}
