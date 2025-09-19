struct RandomTextGenerator {

    private var options: RandomTextGenerateOption = []
    private var textLength: Int = 8

    func getRandomText() -> String {
        var optionPools: [[Character]] = []

        let lowercase = Array("abcdefghijklmnopqrstuvwxyz")
        if options.contains(.alphabetLowercaseLetter) {
            optionPools.append(lowercase)
        }

        let uppercase = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        if options.contains(.alphabetCapitalLetter) {
            optionPools.append(uppercase)
        }

        let numbers = Array("0123456789")
        if options.contains(.number) {
            optionPools.append(numbers)
        }

        let specials = Array("!#$%&()*+-/;<=>?@[]^{}")
        if options.contains(.specialCharacter) {
            optionPools.append(specials)
        }

        guard !optionPools.isEmpty else { return "" }

        let optionCount = optionPools.count
        let baseCount = textLength / optionCount
        var remainder = textLength % optionCount

        var counts = Array(repeating: baseCount, count: optionCount)
        while remainder > 0 {
            let idx = Int.random(in: 0..<optionCount)
            counts[idx] += 1
            remainder -= 1
        }

        var result: [Character] = []
        for (i, pool) in optionPools.enumerated() {
            for _ in 0..<counts[i] {
                result.append(pool.randomElement()!)
            }
        }

        result.shuffle()
        return String(result)
    }

    mutating func toggleOption(for option: RandomTextGenerateOption) {
        if options.contains(option) {
            self.options.remove(option)
        } else {
            self.options.insert(option)
        }
    }

    mutating func setTextLength(_ length: Int) {
        self.textLength = length
    }
}

struct RandomTextGenerateOption: OptionSet {
    let rawValue: Int

    static let alphabetLowercaseLetter = RandomTextGenerateOption(rawValue: 1 << 0)
    static let alphabetCapitalLetter = RandomTextGenerateOption(rawValue: 1 << 1)
    static let number = RandomTextGenerateOption(rawValue: 1 << 2)
    static let specialCharacter = RandomTextGenerateOption(rawValue: 1 << 3)

    static let allOptions: RandomTextGenerateOption = [
        alphabetLowercaseLetter, alphabetCapitalLetter, number, specialCharacter,
    ]
}
