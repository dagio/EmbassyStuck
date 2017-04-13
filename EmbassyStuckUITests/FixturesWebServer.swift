import Foundation
import Embassy
import Ambassador

public class FixturesWebServer {

    private var eventLoop: SelectorEventLoop
    private var router: BestRouter
    private var server: DefaultHTTPServer

    private var eventLoopThreadCondition: NSCondition!
    private var eventLoopThread: Thread!

    public init() {
        eventLoop = try! SelectorEventLoop(selector: try! KqueueSelector())
        router = BestRouter()
        server = DefaultHTTPServer(
            eventLoop: eventLoop,
            interface: "0.0.0.0",
            port: 8090,
            app: router.app
        )
    }

    public func start() {
        try! server.start()

        eventLoopThreadCondition = NSCondition()
        eventLoopThread = Thread(target: self, selector: #selector(runEventLoop), object: nil)
        eventLoopThread.start()
    }

    public func mock(path: String, with fileName: String) {
        self.mock(route: Route(method: .GET, path: "^\(path)$"), with: fileName)
    }

    public func mock(route: Route, with fileName: String) {

        router[route] = DataResponse(
            statusCode: 200,
            statusMessage: "OK",
            contentType: "application/json",
            headers: []
        ) { (_, sendData) in
            let bundle = Bundle(identifier: "com.tapdm.LiveScore.AppTestsHelpers")!
            let path = bundle.path(forResource: fileName, ofType: "json")
            var text = try! String(contentsOfFile: path!, encoding: String.Encoding.utf8)

            sendData(Data(text.utf8))
        }
    }

    public func clearMocks() {
        fatalError("Not implemented")
    }

    public func stop() {
        server.stopAndWait()
        eventLoopThreadCondition.lock()
        eventLoop.stop()
        while eventLoop.running {
            if !eventLoopThreadCondition.wait(until: Date().addingTimeInterval(10)) {
                fatalError("Join eventLoopThread timeout")
            }
        }
    }

    @objc private func runEventLoop() {
        eventLoop.runForever()
        eventLoopThreadCondition.lock()
        eventLoopThreadCondition.signal()
        eventLoopThreadCondition.unlock()
    }
}
