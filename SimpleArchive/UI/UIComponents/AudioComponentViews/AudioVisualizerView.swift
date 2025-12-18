import AVFAudio
import UIKit

final class AudioVisualizerView: UIView {

    private let barCount = 7
    private var bars: [UIView] = (0..<7).map { _ in UIView() }
    private var waveWidth: CGFloat = 1
    private var waveSpacing: CGFloat
    private var audioVisualizeTimer: Timer?
    private var viewHeight: CGFloat = 0
    private var barHeights: [[Float]] = []
    private var totalFrames: Int = 0
    private var visualizerProgress = 0
    private var duration: TimeInterval = .zero

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

    deinit { removeVisuzlization() }

    func activateAudioVisualizer(samplesCount: Int, scaledSamples: [[Float]], sampleRate: Double) {
        let visualizerSize = self.frame.size
        bars.forEach { self.addSubview($0) }

        bars.enumerated()
            .forEach { i, v in
                let barWidth = visualizerSize.width / CGFloat(barCount)
                v.frame = CGRect(
                    x: CGFloat(i) * barWidth,
                    y: 0,
                    width: barWidth - waveSpacing,
                    height: 0
                )
                v.backgroundColor = colors[i]
            }

        startAnimatingBars(
            barHeights: scaledSamples,
            viewHeight: visualizerSize.height,
            duration: Double(samplesCount) / sampleRate)
    }

    private func startAnimatingBars(barHeights: [[Float]], viewHeight: CGFloat, duration: TimeInterval) {
        guard !barHeights.isEmpty else { return }
        self.viewHeight = viewHeight
        self.barHeights = barHeights
        self.totalFrames = barHeights.count
        self.duration = duration

        let interval = duration / Double(totalFrames)

        audioVisualizeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { return }
            if self.visualizerProgress >= self.totalFrames {
                timer.invalidate()
                print("waveform animation finished")
                return
            }

            UIView.animate(withDuration: interval) {
                for (i, bar) in self.bars.enumerated() {
                    let barHeight = viewHeight * CGFloat(barHeights[self.visualizerProgress][i])
                    let y = (viewHeight - barHeight) / 2
                    bar.frame.origin.y = y
                    bar.frame.size.height = barHeight
                }
            }
            self.visualizerProgress += 1
            print("\(self.visualizerProgress) : \(self.totalFrames)")
        }
        RunLoop.main.add(audioVisualizeTimer!, forMode: .common)
    }
}

extension AudioVisualizerView: AudioVisualizerController {

    func resumeVisuzlization() {
        let totalFrames = barHeights.count
        let interval = duration / Double(totalFrames)
        audioVisualizeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { return }
            if self.visualizerProgress >= self.totalFrames {
                timer.invalidate()
                print("waveform animation finished")
                return
            }

            UIView.animate(withDuration: interval) {
                for (i, bar) in self.bars.enumerated() {
                    let barHeight = self.viewHeight * CGFloat(self.barHeights[self.visualizerProgress][i])
                    let y = (self.viewHeight - barHeight) / 2
                    bar.frame.origin.y = y
                    bar.frame.size.height = barHeight
                }
            }
            self.visualizerProgress += 1
            print("\(self.visualizerProgress) : \(self.totalFrames)")
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
        visualizerProgress = 0
        bars.forEach { $0.removeFromSuperview() }
    }

    func seekVisuzlization(rate: TimeInterval) {
        visualizerProgress = Int(Double(totalFrames) * rate)
    }
}

protocol AudioVisualizerController: AnyObject {
    func pauseVisuzlization()
    func removeVisuzlization()
    func resumeVisuzlization()
    func seekVisuzlization(rate: TimeInterval)
}
