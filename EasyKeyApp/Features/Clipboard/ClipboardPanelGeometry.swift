import CoreGraphics

/// Pure placement of the clipboard panel relative to the pointer. Works in the
/// global bottom-left coordinate space AppKit uses for `NSEvent.mouseLocation`
/// and `NSScreen`. The panel is offset from the cursor and clamped fully inside
/// the visible frame so it never overlaps the menu bar or Dock.
func clipboardPanelOrigin(
    mouseLocation: CGPoint,
    panelSize: CGSize,
    visibleFrame: CGRect,
    offset: CGFloat = 8
) -> CGPoint {
    var originX = mouseLocation.x + offset
    var originY = mouseLocation.y - offset - panelSize.height

    let maxX = max(visibleFrame.minX, visibleFrame.maxX - panelSize.width)
    let maxY = max(visibleFrame.minY, visibleFrame.maxY - panelSize.height)

    originX = min(max(originX, visibleFrame.minX), maxX)
    originY = min(max(originY, visibleFrame.minY), maxY)

    return CGPoint(x: originX, y: originY)
}
