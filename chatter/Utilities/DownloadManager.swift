//
//  DownloadManager.swift
//  chatter
//

import Foundation
import Combine
/// Manages media downloads to the app's Documents/Chatter folder,
/// which is visible in the iOS Files app under On My iPhone → Chatter.
@MainActor
final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    // MARK: - Published State

    @Published var isDownloading = false
    @Published var downloadResult: DownloadResult? = nil

    // MARK: - Types

    enum DownloadResult: Equatable {
        case success(folder: String)   // e.g. "Chatter/Photos"
        case failure(String)
    }

    // MARK: - Private

    init() {
        createChatterFolders()
    }

    // MARK: - Public

    /// Downloads media from the given URL and saves it to the appropriate subfolder.
    /// - Parameters:
    ///   - urlString: The remote URL string of the media.
    ///   - mediaType: `.image` saves to Chatter/Photos, `.video` saves to Chatter/Videos.
    func download(urlString: String?, mediaType: MediaType) async {
        guard let urlString = urlString, let url = URLResolver.resolve(urlString) else {
            downloadResult = .failure("Invalid media URL")
            return
        }

        guard !isDownloading else { return }
        isDownloading = true
        downloadResult = nil

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                downloadResult = .failure("Download failed: bad server response")
                isDownloading = false
                return
            }

            let destinationFolder: URL
            let folderName: String

            switch mediaType {
            case .image:
                destinationFolder = photosDirectory
                folderName = "Chatter/Photos"
            case .video:
                destinationFolder = videosDirectory
                folderName = "Chatter/Videos"
            default:
                downloadResult = .failure("Unsupported media type")
                isDownloading = false
                return
            }

            let fileExtension = fileExtensionFor(url: url, mediaType: mediaType)
            let timestamp = Int(Date().timeIntervalSince1970)
            let fileName = "chatter_\(timestamp).\(fileExtension)"
            let destinationURL = destinationFolder.appendingPathComponent(fileName)

            try data.write(to: destinationURL, options: .atomic)

            isDownloading = false
            downloadResult = .success(folder: folderName)

        } catch {
            isDownloading = false
            downloadResult = .failure("Download failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Directories

    private var chatterDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Chatter", isDirectory: true)
    }

    private var photosDirectory: URL {
        chatterDirectory.appendingPathComponent("Photos", isDirectory: true)
    }

    private var videosDirectory: URL {
        chatterDirectory.appendingPathComponent("Videos", isDirectory: true)
    }

    private func createChatterFolders() {
        let fm = FileManager.default
        for dir in [photosDirectory, videosDirectory] {
            if !fm.fileExists(atPath: dir.path) {
                try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
        }
    }

    // MARK: - Helpers

    private func fileExtensionFor(url: URL, mediaType: MediaType) -> String {
        let pathExt = url.pathExtension.lowercased()
        if !pathExt.isEmpty { return pathExt }
        switch mediaType {
        case .image: return "jpg"
        case .video: return "mp4"
        default:     return "bin"
        }
    }
}
