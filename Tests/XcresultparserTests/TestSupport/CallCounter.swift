/// Counts calls made to a test double, which may be called concurrently.
actor CallCounter {
    private(set) var count = 0

    /// Records a call and returns how many calls there have been, including this one.
    @discardableResult
    func increment() -> Int {
        count += 1
        return count
    }
}
