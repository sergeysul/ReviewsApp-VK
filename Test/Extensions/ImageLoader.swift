import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private var runningTasks = [UUID: URLSessionDataTask]()
    private let queue = DispatchQueue(label: "ImageLoader.Queue", attributes: .concurrent)

    private init() {}

    @discardableResult
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) -> UUID? {
        if let cached = cache.object(forKey: urlString as NSString) {
            completion(cached)
            return nil
        }

        guard let url = URL(string: urlString) else {
            completion(nil)
            return nil
        }

        let uuid = UUID()

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            defer { self?.removeTask(for: uuid) }

            guard let self = self else {
                completion(nil)
                return
            }

            if let data = data, let image = UIImage(data: data) {
                self.cache.setObject(image, forKey: urlString as NSString)
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }

        task.resume()

        setTask(task, for: uuid)

        return uuid
    }

    func cancelLoad(for uuid: UUID?) {
        guard let uuid else { return }

        queue.async(flags: .barrier) {
            self.runningTasks[uuid]?.cancel()
            self.runningTasks.removeValue(forKey: uuid)
        }
    }

    // MARK: - Private

    private func setTask(_ task: URLSessionDataTask, for uuid: UUID) {
        queue.async(flags: .barrier) {
            self.runningTasks[uuid] = task
        }
    }

    private func removeTask(for uuid: UUID) {
        queue.async(flags: .barrier) {
            self.runningTasks.removeValue(forKey: uuid)
        }
    }
}
