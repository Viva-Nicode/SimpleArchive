import UIKit

final class SignatureDrawingView: UIView {
    private var path = UIBezierPath()
    private var paths: [UIBezierPath] = []
    private var displayLink: CADisplayLink?
    private var currentTouch: UITouch?
    var signatureSnapshot: [UIView] = []
    var isTailEffect = true
    var isVerifing = true
    var tailLength = 12
    private var allPoints: [CGPoint] = []

    var finishDrawing: (([[Double]]) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white.withAlphaComponent(0.01)
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil

        var points: [CGPoint] = []

        path.cgPath.applyWithBlock { element in
            switch element.pointee.type {
                case .moveToPoint, .addLineToPoint: points.append(element.pointee.points[0])
                default: break
            }
        }

        if let maxX = points.map({ $0.x }).max(),
            let minX = points.map({ $0.x }).min(),
            let maxY = points.map({ $0.y }).max(),
            let minY = points.map({ $0.y }).min(),
            let signSnapshot = self.resizableSnapshotView(
                from: CGRect(x: minX - 20, y: minY - 20, width: maxX - minX + 50, height: maxY - minY + 50),
                afterScreenUpdates: true,
                withCapInsets: .zero)
        {
            signSnapshot.frame.origin = .init(x: minX - 20, y: minY - 20)
            signSnapshot.backgroundColor = AppAppearanceManager.shared.appBaseColor.withAlphaComponent(0.5)
            signSnapshot.layer.cornerRadius = 20

            signatureSnapshot.append(signSnapshot)
			finishDrawing?(points.map { [Double($0.x), Double($0.y)] })
        }
    }

    @objc private func update() {
        guard let touch = currentTouch else { return }
        let point = touch.location(in: self)
        path.addLine(to: point)
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopDisplayLink()
        currentTouch = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopDisplayLink()
        currentTouch = nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        currentTouch = touch
        let point = touch.location(in: self)

        path = UIBezierPath()
        path.lineWidth = 4
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: point)
        paths.append(path)
        allPoints.append(point)

        startDisplayLink()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let coalesced = event?.coalescedTouches(for: touch) ?? [touch]
        coalesced.forEach { t in
            let point = t.location(in: self)
            path.addLine(to: point)
            allPoints.append(point)
        }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        AppAppearanceManager.shared.appTintColor.setStroke()

        if isTailEffect && isVerifing {
            let visiblePoints = Array(allPoints.suffix(tailLength))
            guard visiblePoints.count > 1 else { return }

            let tailPath = UIBezierPath()
            tailPath.lineWidth = 4
            tailPath.lineCapStyle = .round
            tailPath.lineJoinStyle = .round
            tailPath.move(to: visiblePoints[0])
            visiblePoints.dropFirst().forEach { tailPath.addLine(to: $0) }
            tailPath.stroke()

        } else {
            paths.forEach {
                $0.lineWidth = 4
                $0.stroke()
            }
        }
    }

    func clear() {
        paths.removeAll()
        allPoints.removeAll()
        setNeedsDisplay()
    }
}

enum DrawingDisplayOption: String, Codable {
    case shown = "shown"
    case partial = "partial"
    case hidden = "hidden"
}
