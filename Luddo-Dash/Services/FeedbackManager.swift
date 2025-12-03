//
//  FeedbackManager.swift
//  Luddo-Dash
//
//  Haptic and sound feedback manager
//

import UIKit
import AudioToolbox

// MARK: - Feedback Manager
class FeedbackManager {
    static let shared = FeedbackManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        // Prepare generators for immediate response
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Impact Feedback

    /// Light haptic feedback - for subtle interactions
    func lightHaptic() {
        lightGenerator.impactOccurred()
    }

    /// Medium haptic feedback - for standard interactions
    func mediumHaptic() {
        mediumGenerator.impactOccurred()
    }

    /// Heavy haptic feedback - for significant interactions
    func heavyHaptic() {
        heavyGenerator.impactOccurred()
    }

    // MARK: - Selection Feedback

    /// Selection changed feedback - for tab changes, picker selections
    func selectionHaptic() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - Notification Feedback

    /// Success notification feedback
    func successHaptic() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning notification feedback
    func warningHaptic() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error notification feedback
    func errorHaptic() {
        notificationGenerator.notificationOccurred(.error)
    }

    // MARK: - Sound Effects

    /// Play system click sound
    func playClickSound() {
        AudioServicesPlaySystemSound(1104)
    }

    /// Play system tap sound
    func playTapSound() {
        AudioServicesPlaySystemSound(1306)
    }

    // MARK: - Combined Feedback

    /// Snap haptic with sound - for carousel item centering
    func snapHaptic() {
        heavyGenerator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.lightGenerator.impactOccurred()
        }
    }

    /// Tab selection feedback - haptic + sound
    func tabSelectionFeedback() {
        selectionHaptic()
        playClickSound()
    }

    /// Button tap feedback
    func buttonTapFeedback() {
        mediumHaptic()
    }

    /// Card tap feedback
    func cardTapFeedback() {
        lightHaptic()
    }

    /// Refresh success feedback
    func refreshSuccessFeedback() {
        successHaptic()
    }

    /// Refresh error feedback
    func refreshErrorFeedback() {
        errorHaptic()
    }
}
