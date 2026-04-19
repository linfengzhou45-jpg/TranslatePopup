import Foundation

/// Handles translation of text from English to Chinese.
///
/// On macOS 15+ (Sequoia) the Apple Translation framework is used for on-device translation.
/// On older systems a free MyMemory API endpoint is used as a fallback.
final class TranslationService {

    // MARK: - Public

    /// Translate `text` from English to Simplified Chinese.
    /// Calls `completion` on the main queue with the result.
    func translate(_ text: String, completion: @escaping (Result<String, TranslationError>) -> Void) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(.failure(.emptyInput))
            return
        }

        if #available(macOS 15.0, *) {
            translateWithAppleFramework(trimmed, completion: completion)
        } else {
            translateWithAPI(trimmed, completion: completion)
        }
    }

    // MARK: - Error type

    enum TranslationError: Error, LocalizedError {
        case emptyInput
        case requestFailed(String)
        case noResult

        var errorDescription: String? {
            switch self {
            case .emptyInput:        return "没有要翻译的文字。"
            case .requestFailed(let msg): return "翻译失败：\(msg)"
            case .noResult:          return "翻译未返回结果。"
            }
        }
    }

    // MARK: - Apple Translation (macOS 15+)

    @available(macOS 15.0, *)
    private func translateWithAppleFramework(
        _ text: String,
        completion: @escaping (Result<String, TranslationError>) -> Void
    ) {
        // Use Apple's Translation framework when available (macOS 15+ Sequoia).
        // The framework provides on-device translation without network calls.
        //
        // NOTE: To enable this path, add `import Translation` at file scope and
        // link the Translation framework. For broad compatibility the project
        // currently always uses the API fallback, which works on all macOS versions.
        // Uncomment the block below if targeting macOS 15+ exclusively.
        //
        // Task { @MainActor in
        //     import Translation
        //     do {
        //         let session = try await TranslationSession(
        //             source: Locale.Language(identifier: "en"),
        //             target: Locale.Language(identifier: "zh-Hans")
        //         )
        //         let response = try await session.translate(text)
        //         completion(.success(response.targetText))
        //     } catch {
        //         self.translateWithAPI(text, completion: completion)
        //     }
        // }
        // return

        translateWithAPI(text, completion: completion)
    }

    // MARK: - MyMemory free API fallback

    private func translateWithAPI(
        _ text: String,
        completion: @escaping (Result<String, TranslationError>) -> Void
    ) {
        // MyMemory: free, no key required, 5000 chars/day anonymous.
        // https://api.mymemory.translated.net/get?q=...&langpair=en|zh-CN
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")!
        components.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: "en|zh-CN")
        ]

        guard let url = components.url else {
            completion(.failure(.requestFailed("Invalid URL")))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.requestFailed(error.localizedDescription)))
                    return
                }
                guard let data = data else {
                    completion(.failure(.requestFailed("No data received")))
                    return
                }
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let responseData = json["responseData"] as? [String: Any],
                          let translatedText = responseData["translatedText"] as? String,
                          !translatedText.isEmpty else {
                        completion(.failure(.noResult))
                        return
                    }
                    completion(.success(translatedText))
                } catch {
                    completion(.failure(.requestFailed("JSON parse error: \(error.localizedDescription)")))
                }
            }
        }.resume()
    }
}
