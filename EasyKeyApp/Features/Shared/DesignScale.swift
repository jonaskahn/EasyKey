import SwiftUI

/// Corner-radius tokens. sm matches inset fields/controls, md matches cards/icons —
/// values are unchanged from prior ad-hoc literals, this is a rename only.
enum DesignScale {
    static let radiusSM: CGFloat = 6
    static let radiusMD: CGFloat = 8
}

extension View {
    func easyKeyButtonShape() -> some View {
        buttonBorderShape(.roundedRectangle(radius: DesignScale.radiusMD))
    }
}
