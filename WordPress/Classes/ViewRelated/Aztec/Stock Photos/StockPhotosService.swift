
import Foundation


/// Encapsulates search parameters (text, pagination, etc)
struct StockPhotosSearchParams {
    let text: String
}


/// Abstracts the serive used to fetch Stock Photos
protocol StockPhotosService {
    func search(params: StockPhotosSearchParams, completion: @escaping ([StockPhotosMedia]) -> Void)
}

/// Default implementation of the Stock Photos Service, attacking a blog's restful api
final class DefaultStockPhotosService: StockPhotosService {
    private let endPoint = "/rest/v1/meta/external-media/pexels"

    private struct Parameters {
        static let search = "search"
    }

    private struct ParsingKeys {
        static let media = "media"
    }

    private let api: WordPressComRestApi

    init(api: WordPressComRestApi) {
        self.api = api
    }

    func search(params: StockPhotosSearchParams, completion: @escaping ([StockPhotosMedia]) -> Void) {
        api.GET(endPoint, parameters: parameters(params: params), success: { results, response in
            if let media = results[ParsingKeys.media] {
                do {
                    let json = try JSONSerialization.data(withJSONObject: media as Any)
                    let parsedResponse = try JSONDecoder().decode([StockPhotosMedia].self, from: json)

                    completion(parsedResponse)
                } catch {
                    // Not sure how to handle this
                    completion([])
                }
            }
        }) { error, response in
            // I am not sure how we are going to handle errors. In the meantime, I'm returning an empty result
            completion([])
        }
    }

    private func parameters(params: StockPhotosSearchParams) -> [String: AnyObject] {
        return [Parameters.search: params.text as AnyObject]
    }
}

// MARK: - Temporary mock for testing

final class StockPhotosServiceMock: StockPhotosService {
    func search(params: StockPhotosSearchParams, completion: @escaping ([StockPhotosMedia]) -> Void) {
        let text = params.text
        guard text.count > 0 else {
            completion([])
            return
        }
        DispatchQueue.global().async {
            let totalMedia = text.count
            let mediaResult = (1...totalMedia).map { self.crateStockPhotosMedia(id: "\($0)") }
            DispatchQueue.main.async {
                completion(mediaResult)
            }
        }
    }

    private func crateStockPhotosMedia(id: String) -> StockPhotosMedia {
        let url = "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940".toURL()!
        let thumbs = ThumbnailCollection(
            largeURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940".toURL()!,
            mediumURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&h=350".toURL()!,
            postThumbnailURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&h=130".toURL()!,
            thumbnailURL: "https://images.pexels.com/photos/710916/pexels-photo-710916.jpeg?auto=compress&cs=tinysrgb&fit=crop&h=200&w=280".toURL()!
        )
        return StockPhotosMedia(
            id: id,
            URL: url,
            title: "pexels-photo-710916.jpeg",
            name: "pexels-photo-710916.jpeg",
            size:
            CGSize(width: 1880, height: 1253),
            thumbnails: thumbs
        )
    }
}

private extension String {
    func toURL() -> URL? {
        return URL(string: self)
    }
}