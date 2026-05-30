//
//  HorizontalSwipeGestureMonitor.swift
//  SayBar
//
//  Created by Gale Williams on 5/30/26.
//

import AppKit
import SwiftUI

struct HorizontalSwipeGestureMonitor: NSViewRepresentable {
    let threshold: CGFloat
    let onSwipe: (MenuBarDisplaySupport.SurfaceNavigationDirection) -> Void

    init(
        threshold: CGFloat = 90,
        onSwipe: @escaping (MenuBarDisplaySupport.SurfaceNavigationDirection) -> Void
    ) {
        self.threshold = threshold
        self.onSwipe = onSwipe
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(threshold: threshold, onSwipe: onSwipe)
    }

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        context.coordinator.trackingView = view
        context.coordinator.installMonitor()
        return view
    }

    func updateNSView(_ nsView: TrackingView, context: Context) {
        context.coordinator.threshold = threshold
        context.coordinator.onSwipe = onSwipe
    }

    static func dismantleNSView(_ nsView: TrackingView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }
}

extension HorizontalSwipeGestureMonitor {
    final class TrackingView: NSView {
        var isPointerInside = false

        private var trackingArea: NSTrackingArea?

        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()

            if let trackingArea {
                removeTrackingArea(trackingArea)
            }

            let area = NSTrackingArea(
                rect: bounds,
                options: [.activeInKeyWindow, .inVisibleRect, .mouseEnteredAndExited],
                owner: self
            )
            addTrackingArea(area)
            trackingArea = area
        }

        override func mouseEntered(with event: NSEvent) {
            isPointerInside = true
        }

        override func mouseExited(with event: NSEvent) {
            isPointerInside = false
        }
    }

    final class Coordinator: NSObject {
        weak var trackingView: TrackingView?
        var threshold: CGFloat
        var onSwipe: (MenuBarDisplaySupport.SurfaceNavigationDirection) -> Void

        private var monitor: Any?
        private var accumulatedDeltaX: CGFloat = 0
        private var didEmitSwipeForCurrentGesture = false

        init(
            threshold: CGFloat,
            onSwipe: @escaping (MenuBarDisplaySupport.SurfaceNavigationDirection) -> Void
        ) {
            self.threshold = threshold
            self.onSwipe = onSwipe
        }

        func installMonitor() {
            guard monitor == nil else {
                return
            }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handleScrollWheelEvent(event)
                return event
            }
        }

        func removeMonitor() {
            guard let monitor else {
                return
            }

            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }

        private func handleScrollWheelEvent(_ event: NSEvent) {
            guard trackingView?.isPointerInside == true else {
                resetGesture()
                return
            }

            if event.phase == .began || event.momentumPhase == .began {
                resetGesture()
            }

            let horizontalDelta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaX : event.deltaX
            let verticalDelta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.deltaY
            guard abs(horizontalDelta) > abs(verticalDelta) * 1.4 else {
                return
            }

            accumulatedDeltaX += horizontalDelta
            guard !didEmitSwipeForCurrentGesture else {
                return
            }

            if accumulatedDeltaX >= threshold {
                didEmitSwipeForCurrentGesture = true
                onSwipe(.previous)
            } else if accumulatedDeltaX <= -threshold {
                didEmitSwipeForCurrentGesture = true
                onSwipe(.next)
            }

            if event.phase == .ended
                || event.phase == .cancelled
                || event.momentumPhase == .ended
                || event.momentumPhase == .cancelled {
                resetGesture()
            }
        }

        private func resetGesture() {
            accumulatedDeltaX = 0
            didEmitSwipeForCurrentGesture = false
        }
    }
}
