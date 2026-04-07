import XCTest
@testable import Vibe

final class VibeTests: XCTestCase {
    func testHapticsInitialization() throws {
        let manager = HapticsManager()
        manager.prepare()
        // Note: Real haptics won't start in a simulator/CI runner, 
        // but we can test that the manager doesn't crash.
        XCTAssertNotNil(manager)
    }
    
    func testPhysicsSceneInitialization() throws {
        let size = CGSize(width: 375, height: 812)
        let scene = PhysicsScene(size: size)
        XCTAssertEqual(scene.size, size)
        XCTAssertEqual(scene.backgroundColor, .black)
    }
}
