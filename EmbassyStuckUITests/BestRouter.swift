import Foundation
import Ambassador

public struct Route: Hashable {

    public enum Method: String {
        case GET
        case POST
        case PUT
        case DELETE
    }

    public let method: Method
    public let path: String
    public let queryString: [String: String]

    public init(method: Method, path: String, queryString: [String: String]) {
        self.method = method
        self.path = path
        self.queryString = queryString
    }

    public init(method: Method, path: String) {
        self.init(method: method, path: path, queryString: [:])
    }

    public init(path: String) {
        self.init(method: .GET, path: path, queryString: [:])
    }

    public init(path: String, queryString: [String: String]) {
        self.init(method: .GET, path: path, queryString: queryString)
    }

    public var hashValue: Int {
        return method.rawValue.hashValue
               ^ path.hashValue
               ^ queryString.reduce(0) { $0 ^ $1.0.hashValue ^ $1.1.hashValue }
    }

    public static func ==(lhs: Route, rhs: Route) -> Bool {
        return lhs.method == rhs.method
            && lhs.path == rhs.path
            && lhs.queryString == rhs.queryString
    }
}

/// Best Router Ever - Més que un router
/// This router provide the following features compare to the original one
///  - The same one (copy - pasted)
///  - Crash instead of 404 when a mock is missing
///  - Can also match particular HTTP method

class BestRouter: WebApp {

    private var routes: [Route: WebApp] = [:]

    private let semaphore = DispatchSemaphore(value: 1)

    public init() {
    }

    open subscript(route: Route) -> WebApp? {
        get {
            // enter critical section
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            defer {
                semaphore.signal()
            }
            return routes[route]
        }

        set {
            // enter critical section
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            defer {
                semaphore.signal()
            }
            routes[route] = newValue!
        }
    }

    open func app(
            _ environ: [String: Any],
            startResponse: @escaping ((String, [(String, String)]) -> Void),
            sendBody: @escaping ((Data) -> Void)
    ) {
        let path = environ["PATH_INFO"] as! String
        let method = environ["REQUEST_METHOD"] as! String
        let queryString = parseQueryString(environ)
        let route = Route(method: Route.Method(rawValue: method)!, path: path, queryString: queryString)

        if let (webApp, captures) = matchRoute(to: route) {
            var environ = environ
            environ["ambassador.router_captures"] = captures
            webApp.app(environ, startResponse: startResponse, sendBody: sendBody)

            return
        }

        // We prefer to crash if there is any request not mocked so we know the test is incomplete
        fatalError("Request with path \(path) is not mocked")
    }

    /**
    Match the search route on the list of routes

    - parameter to: The route that need to be matched

    - returns: The WebApp and captured string
    */
    private func matchRoute(to searchRoute: Route) -> (WebApp, [String])? {
        routeLoop: for (route, webApp) in routes {

            // First easy check : the method
            guard route.method == searchRoute.method else {
                continue
            }

            // Then check the path, trying first with regex
            let regex = try! NSRegularExpression(pattern: route.path, options: [])
            let matches = regex.matches(
                in: searchRoute.path,
                options: [],
                range: NSRange(location: 0, length: searchRoute.path.characters.count)
            )

            if matches.isEmpty {
                continue
            }

            let searchPath = searchRoute.path as NSString
            let match = matches[0]
            var captures = [String]()
            for rangeIdx in 1..<match.numberOfRanges {
                captures.append(searchPath.substring(with: match.rangeAt(rangeIdx)))
            }

            // Third, check the query path
            // Check that all arguments from the route are included in the
            // the search route
            for (routeQueryKey, routeQueryValue) in route.queryString {
                let containsArgument = searchRoute.queryString.contains { (searchQueryName, searchQueryValue) in
                    routeQueryKey == searchQueryName && routeQueryValue == searchQueryValue
                }

                if !containsArgument {
                    // This query is missing from the search route
                    // so this route does not match, go to the next o
                    continue routeLoop
                }
            }

            return (webApp, captures)
        }

        return nil
    }
}

fileprivate func parseQueryString(_ environ: [String: Any]) -> [String: String] {

    guard let query = environ["QUERY_STRING"] as? String else {
        return [:]
    }

    var results = [String: String]()

    let keyValues = query.components(separatedBy: "&")
    if keyValues.count > 0 {
        for pair in keyValues {
            let kv = pair.components(separatedBy: "=")
            if kv.count > 1 {
                results.updateValue(kv[1], forKey: kv[0])
            }
        }
    }

    return results
}
