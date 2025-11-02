import AVFAudio
import UIKit

class AudioVisualizerView: UIView {

    private let barCount = 7
    private var bars: [UIView] = (0..<7).map { _ in UIView() }
    private var waveWidth: CGFloat = 1
    private var waveSpacing: CGFloat
    private var audioVisualizeTimer: Timer?
    private var viewHeight: CGFloat = 0
    private var heights: [Float] = []
    private var totalFrames: Int = 0
    private var index = 0
    private var duration: TimeInterval = .zero

    var audioURL: URL? {
        didSet {
            guard let url = audioURL else { return }
            animateBars(from: url, viewSize: self.frame.size)
        }
    }
    private var colors: [UIColor] = [
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemGreen,
        .systemBlue,
        .systemIndigo,
        .systemPurple,
    ]

    init(waveWidth: CGFloat = 1, waveSpacing: CGFloat = 2) {
        self.waveWidth = waveWidth
        self.waveSpacing = waveSpacing
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("deinit AudioVisualizerView")
        removeVisuzlization()
    }

    private func animateBars(from audioUrl: URL, viewSize: CGSize) {
        bars.forEach { self.addSubview($0) }

        bars.enumerated()
            .forEach { i, v in
                let barWidth = viewSize.width / CGFloat(barCount)
                v.frame = CGRect(
                    x: CGFloat(i) * barWidth,
                    y: 0,
                    width: barWidth - waveSpacing,
                    height: 0
                )
                v.backgroundColor = colors[i]
            }

        readBuffer(audioUrl) { samples, sampleRate in
            guard let samples = samples, let sampleRate = sampleRate else {
                return
            }

            let heights = self.makeBarHeightArray(samples, sampleRate)
            self.startAnimatingBars(
                heights: heights,
                viewHeight: viewSize.height,
                duration: Double(samples.count) / sampleRate)
        }
    }

    private func readBuffer(
        _ audioUrl: URL, completion: @escaping (_ wave: UnsafeBufferPointer<Float>?, _ sampleRate: Double?) -> Void
    ) {
        DispatchQueue.global(qos: .utility)
            .async {
                guard let file = try? AVAudioFile(forReading: audioUrl) else {
                    completion(nil, nil)
                    return
                }

                let audioFormat = file.processingFormat
                let audioFrameCount = UInt32(file.length)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
                else { return completion(UnsafeBufferPointer<Float>(_empty: ()), nil) }
                do {
                    try file.read(into: buffer)
                } catch {
                    print(error)
                }

                let floatArray = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))

                DispatchQueue.main.sync {
                    completion(floatArray, file.fileFormat.sampleRate)
                }
            }
    }

    private func makeBarHeightArray(_ wave: UnsafeBufferPointer<Float>, _ sampleRate: Double) -> [Float] {

        let samplesPerBar = Int(sampleRate / Double(barCount))
        var result: [Float] = []

        for i in 0..<(wave.count / samplesPerBar) {
            let segment = wave[i * samplesPerBar..<(i + 1) * samplesPerBar]
            let avg = segment.map { abs($0) }.reduce(0, +) / Float(segment.count)
            result.append(avg)
        }

        guard let maxValue = result.max(), maxValue > 0 else { return result }
        let scaled = result.map { ($0 / maxValue) }

        return scaled
    }

    private func startAnimatingBars(heights: [Float], viewHeight: CGFloat, duration: TimeInterval) {
        guard !heights.isEmpty else { return }
        self.viewHeight = viewHeight
        self.heights = heights
        self.totalFrames = heights.count
        self.duration = duration

        let interval = duration / Double(totalFrames)

        audioVisualizeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { return }
            if self.index >= self.totalFrames {
                timer.invalidate()
                print("waveform animation finished")
                return
            }

            let barHeights = self.makeBarSet(from: heights[self.index])

            UIView.animate(withDuration: interval) {
                for (i, bar) in self.bars.enumerated() {
                    let barHeight = CGFloat(barHeights[i]) * viewHeight
                    let y = (viewHeight - barHeight) / 2
                    bar.frame.origin.y = y
                    bar.frame.size.height = barHeight
                }
            }
            self.index += 1
            print("\(self.index) : \(self.totalFrames)")
        }
        RunLoop.main.add(audioVisualizeTimer!, forMode: .common)
    }

    private func makeBarSet(from baseValue: Float) -> [Float] {
        (0..<barCount)
            .map { _ in
                let variation = Float.random(in: -0.3...0.3)
                return max(0.05, min(1.0, baseValue + variation))
            }
    }
}

protocol AudioVisualizerController: AnyObject {
    func pauseVisuzlization()
    func removeVisuzlization()
    func restartVisuzlization()
    func seekVisuzlization(rate: TimeInterval)
}

extension AudioVisualizerView: AudioVisualizerController {

    func restartVisuzlization() {
        let totalFrames = heights.count
        let interval = duration / Double(totalFrames)
        audioVisualizeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { return }
            if self.index >= self.totalFrames {
                timer.invalidate()
                print("waveform animation finished")
                return
            }

            let barHeights = self.makeBarSet(from: self.heights[self.index])

            UIView.animate(withDuration: interval) {
                for (i, bar) in self.bars.enumerated() {
                    let barHeight = CGFloat(barHeights[i]) * self.viewHeight
                    let y = (self.viewHeight - barHeight) / 2
                    bar.frame.origin.y = y
                    bar.frame.size.height = barHeight
                }
            }
            self.index += 1
            print("\(self.index) : \(self.totalFrames)")
        }
        RunLoop.main.add(audioVisualizeTimer!, forMode: .common)
    }

    func pauseVisuzlization() {
        audioVisualizeTimer?.invalidate()
        UIView.animate(withDuration: 0.1) {
            for bar in self.bars {
                let barHeight = CGFloat(0.1) * self.viewHeight
                let y = (self.viewHeight - barHeight) / 2
                bar.frame.origin.y = y
                bar.frame.size.height = barHeight
            }
        }
    }

    func removeVisuzlization() {
        audioVisualizeTimer?.invalidate()
        audioVisualizeTimer = nil
        audioURL = nil
        index = 0
        bars.forEach { $0.removeFromSuperview() }
    }

    func seekVisuzlization(rate: TimeInterval) {
        index = Int(Double(totalFrames) * rate)
    }
}
