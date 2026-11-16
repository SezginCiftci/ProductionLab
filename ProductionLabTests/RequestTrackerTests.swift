import Testing
@testable import ProductionLab

/// Data race lab regresyonu: aynı anda yapılan kayıtların hiçbiri kaybolmamalı.
/// Thread Sanitizer ile çalıştırın: xcodebuild test ... -enableThreadSanitizer YES
struct RequestTrackerTests {
    @Test func concurrentRecordsAreNotLost() async {
        let tracker = RequestTracker()

        // 100 eşzamanlı görev × 1.000 kayıt
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    for _ in 0..<1_000 {
                        tracker.record()
                    }
                }
            }
        }

        #expect(tracker.totalRequests == 100_000)
    }
}
