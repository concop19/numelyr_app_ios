import Foundation

/// Persistent disk and in-memory cache for Calendar Art images.
/// Limits storage strictly to a rolling window of ±2 days around the target date (up to 5 images).
public final class CalendarArtCache: @unchecked Sendable {
    public static let shared = CalendarArtCache()

    private let memoryCache = NSCache<NSString, NSData>()
    private let fileManager: FileManager
    private let directoryURL: URL
    private let lock = NSLock()

    public init(
        fileManager: FileManager = .default,
        directoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CalendarArt", isDirectory: true)
        self.memoryCache.countLimit = 5

        createDirectoryIfNeeded()
    }

    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }

    public func cacheKey(for url: URL) -> String {
        url.lastPathComponent
    }

    public func fileURL(for url: URL) -> URL {
        directoryURL.appendingPathComponent(cacheKey(for: url))
    }

    /// Synchronous retrieval: Checks memory first, then disk.
    public func data(for url: URL) -> Data? {
        let key = cacheKey(for: url) as NSString
        lock.lock()
        defer { lock.unlock() }

        if let cached = memoryCache.object(forKey: key) {
            return cached as Data
        }

        let file = fileURL(for: url)
        if let data = try? Data(contentsOf: file) {
            memoryCache.setObject(data as NSData, forKey: key)
            return data
        }

        return nil
    }

    /// Stores image data in memory and disk, then immediately purges any files outside the ±2 days window.
    public func store(
        data: Data,
        for url: URL,
        referenceDate: Date = Date(),
        calendar: Calendar = LunarService.defaultCalendar,
        baseURL: URL = CalendarArtEngine.defaultBaseURL
    ) {
        let key = cacheKey(for: url) as NSString
        let file = fileURL(for: url)

        lock.lock()
        memoryCache.setObject(data as NSData, forKey: key)
        try? data.write(to: file, options: .atomic)
        lock.unlock()

        purgeExceptWindow(
            around: referenceDate,
            calendar: calendar,
            baseURL: baseURL
        )
    }

    /// Computes the valid image filenames for the rolling window of ±2 days around centerDate.
    public func activeImageKeys(
        around centerDate: Date,
        calendar: Calendar = LunarService.defaultCalendar,
        baseURL: URL = CalendarArtEngine.defaultBaseURL
    ) -> Set<String> {
        var keys: Set<String> = []
        for offset in -2...2 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: centerDate) else { continue }
            let lunar = LunarService.solarToLunar(date: date, calendar: calendar)
            let art = CalendarArtEngine.item(for: lunar, baseURL: baseURL)
            if let imageURL = art.imageURL {
                keys.insert(cacheKey(for: imageURL))
            }
        }
        return keys
    }

    /// Purges all cached files from disk and memory that are not within the ±2 days window around centerDate.
    public func purgeExceptWindow(
        around centerDate: Date,
        calendar: Calendar = LunarService.defaultCalendar,
        baseURL: URL = CalendarArtEngine.defaultBaseURL
    ) {
        let allowedKeys = activeImageKeys(around: centerDate, calendar: calendar, baseURL: baseURL)

        lock.lock()
        defer { lock.unlock() }

        guard let contents = try? fileManager.contentsOfDirectory(atPath: directoryURL.path) else { return }
        for filename in contents {
            if !allowedKeys.contains(filename) {
                let fileToDelete = directoryURL.appendingPathComponent(filename)
                try? fileManager.removeItem(at: fileToDelete)
                memoryCache.removeObject(forKey: filename as NSString)
            }
        }
    }

    /// Clears both memory and disk cache.
    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        memoryCache.removeAllObjects()
        if let contents = try? fileManager.contentsOfDirectory(atPath: directoryURL.path) {
            for filename in contents {
                try? fileManager.removeItem(at: directoryURL.appendingPathComponent(filename))
            }
        }
    }
}
