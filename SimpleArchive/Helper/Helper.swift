import Foundation

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
