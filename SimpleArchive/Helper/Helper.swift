import Foundation
import OSLog

extension Array {
    mutating func moveElement(src: Int, des: Int) {
        guard src != des,
            src >= 0, src < count,
            des >= 0, des <= count
        else { return }

        let element = remove(at: src)
        insert(element, at: des)
    }
}

extension TimeInterval {
    var asMinuteSecond: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension Float {
    var asMinuteSecond: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension String {
    static var emptyAudioTitle: Self { "no title" }
    static var emptyAudioArtist: Self { "unknown" }
}

final class DebugHelper {
    static let logger = Logger()

    static func myPrint(
        _ message: Any,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        print(
            """
            \("\(file):\(line) > \(function)")
            \(message)
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            """
        )
    }

    static func myLog(
        _ datas: Any...,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let logMsg =
            datas.map { data -> String in
                if let stringData = data as? String {
                    return stringData + "\n"
                } else {
                    var dataInformation = ""
                    dump(data, to: &dataInformation)
                    return dataInformation
                }
            }
            .joined(separator: "")

        logger.debug(
            """
            \("🟧 [\(file):\(line)] \(function)")
            \(logMsg)
            """
        )
    }
}
