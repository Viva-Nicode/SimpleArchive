import Foundation
import XCTest

final class MockURLProtocol: URLProtocol {

    struct ResponseStub {
        let response: HTTPURLResponse
        let data: Data
    }

    static var responseStub: ResponseStub?

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.scheme == "http"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        //        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        //        Self.setProperty("downloadAudio", forKey: "requestType", in: mutableRequest)
        //        return mutableRequest as URLRequest
        request
    }

    override func startLoading() {
        guard let stub = Self.responseStub else {
            XCTFail("No stub for request: \(request)")
            return
        }

        client?.urlProtocol(self, didReceive: stub.response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
