import CoreGraphics

struct TranslationPanelScreenGeometry: Equatable {
    let frame: CGRect
    let visibleFrame: CGRect
}

func translationPanelOrigin(
    pointerLocation: CGPoint,
    panelSize: CGSize,
    screens: [TranslationPanelScreenGeometry],
    offset: CGFloat = 8
) -> CGPoint {
    let screen = screenGeometry(containing: pointerLocation, screens: screens)
        ?? TranslationPanelScreenGeometry(
            frame: CGRect(origin: .zero, size: panelSize),
            visibleFrame: CGRect(origin: .zero, size: panelSize)
        )
    let visibleFrame = screen.visibleFrame
    let maximumX = max(visibleFrame.minX, visibleFrame.maxX - panelSize.width)
    let maximumY = max(visibleFrame.minY, visibleFrame.maxY - panelSize.height)
    let desiredX = pointerLocation.x + offset
    let desiredY = pointerLocation.y - offset - panelSize.height

    return CGPoint(
        x: min(max(desiredX, visibleFrame.minX), maximumX),
        y: min(max(desiredY, visibleFrame.minY), maximumY)
    )
}

private func screenGeometry(
    containing point: CGPoint,
    screens: [TranslationPanelScreenGeometry]
) -> TranslationPanelScreenGeometry? {
    if let containingScreen = screens.first(where: { frame($0.frame, contains: point) }) {
        return containingScreen
    }
    return screens.min { distanceSquared(from: point, to: $0.frame) < distanceSquared(from: point, to: $1.frame) }
}

private func frame(_ frame: CGRect, contains point: CGPoint) -> Bool {
    point.x >= frame.minX && point.x <= frame.maxX && point.y >= frame.minY && point.y <= frame.maxY
}

private func distanceSquared(from point: CGPoint, to frame: CGRect) -> CGFloat {
    let nearestX = min(max(point.x, frame.minX), frame.maxX)
    let nearestY = min(max(point.y, frame.minY), frame.maxY)
    let deltaX = point.x - nearestX
    let deltaY = point.y - nearestY
    return deltaX * deltaX + deltaY * deltaY
}
