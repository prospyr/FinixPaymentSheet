//
//  SwiftUIDemoView.swift
//  PaymentSheetDemo
//
//  Created by Israrul Haque on 25/04/26.
//

import FinixPaymentSheet
import SwiftUI

/// SwiftUI Demo View showcasing PaymentSheet integration
///
/// This demo shows how to integrate PaymentSheet into a SwiftUI app using the `.paymentSheet()` modifier.
/// It demonstrates both inline and push-based navigation patterns.
@available(iOS 15.0, *)
struct SwiftUIDemoView: View {
    // MARK: - State

    @State private var showPaymentSheet = false
    @State private var lastToken: String?
    @State private var lastError: String?
    @State private var presentationStyle: PresentationStyle = .push
    @State private var cardScanning = true
    @State private var showCountry = true
    @State private var showCancelButton = false
    @State private var showCancelItem = false

    // MARK: - Configuration

    private let credentials = FinixCredentials(
        applicationId: APPLICATION_ID,
        environment: .Sandbox
    )

    private var configuration: PaymentInputController.Configuration {
        .init(
            title: "SwiftUI Card Entry",
            branding: PaymentInputController.Branding(
                image: BRANDING_LOGO,
                title: BRANDING_NAME
            ),
            buttonTitle: "Tokenize",
            enableCardScanning: cardScanning
        )
    }

    // MARK: - Body

    var body: some View {
        List {
            // Presentation Style Section
            Section("Presentation Style") {
                Picker("Style", selection: $presentationStyle) {
                    Text("Push Navigation").tag(PresentationStyle.push)
                    Text("Modal Sheet").tag(PresentationStyle.modal)
                }
                .pickerStyle(.segmented)
            }

            // Configuration Section
            Section("Configuration") {
                Toggle("Card Scanning", isOn: $cardScanning)
                Toggle("Show Country", isOn: $showCountry)
                Toggle("Show Cancel Button", isOn: $showCancelButton)
                Toggle("Show Cancel Item", isOn: $showCancelItem)
            }

            // Action Section
            Section {
                Button(action: {
                    lastToken = nil
                    lastError = nil
                    showPaymentSheet = true
                }) {
                    HStack {
                        Text("Show PaymentSheet")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "creditcard")
                    }
                }
            }

            // Result Section
            if let token = lastToken {
                Section("Last Token") {
                    Text(token)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                }
            }

            if let error = lastError {
                Section("Last Error") {
                    Text(error)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.red)
                }
            }

            // Info Section
            Section("Info") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This demo shows PaymentSheet SwiftUI integration")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("• Push style: Pushes onto navigation stack")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("• Modal style: Presents as custom modal sheet")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("• Uses FinixCheckoutTheme1 for consistent styling")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        // Apply PaymentSheet modifier based on presentation style
        .modifier(
            PaymentSheetPresentationModifier(
                isPresented: $showPaymentSheet,
                presentationStyle: presentationStyle,
                credentials: credentials,
                configuration: configuration,
                style: .partial,
                theme: FinixCheckoutTheme1.default,
                showCancelButton: showCancelButton,
                showCancelItem: showCancelItem,
                showCountry: showCountry,
                onSuccess: { token in
                    lastToken = "✅ Token: \(token.id)"
                    lastError = nil
                },
                onCancel: {
                    lastToken = nil
                    lastError = "❌ Cancelled by user"
                },
                onFailure: { error in
                    lastToken = nil
                    lastError = "❌ Error: \(error.localizedDescription)"
                }
            )
        )
    }

    // MARK: - Supporting Types

    enum PresentationStyle {
        case push
        case modal
    }
}

// MARK: - Presentation Modifier

/// Wrapper to conditionally apply payment sheet based on presentation style
@available(iOS 15.0, *)
private struct PaymentSheetPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let presentationStyle: SwiftUIDemoView.PresentationStyle
    let credentials: FinixCredentials
    let configuration: PaymentInputController.Configuration
    let style: PaymentInputController.Style
    let theme: any ColorThemeProtocol
    let showCancelButton: Bool
    let showCancelItem: Bool
    let showCountry: Bool
    let onSuccess: (TokenResponse) -> Void
    let onCancel: () -> Void
    let onFailure: (Error) -> Void

    func body(content: Content) -> some View {
        switch presentationStyle {
        case .push:
            // Push onto navigation stack
            content
                .paymentSheet(
                    isPresented: $isPresented,
                    credentials: credentials,
                    configuration: configuration,
                    style: style,
                    theme: theme,
                    showCancelButton: showCancelButton,
                    showCancelItem: showCancelItem,
                    showCountry: showCountry,
                    onSuccess: onSuccess,
                    onCancel: onCancel,
                    onFailure: onFailure
                )
        case .modal:
            // Present as modal sheet
            content
                .background(
                    PaymentSheetModalBridge(
                        isPresented: $isPresented,
                        credentials: credentials,
                        configuration: configuration,
                        style: style,
                        theme: theme,
                        showCancelButton: showCancelButton,
                        showCancelItem: showCancelItem,
                        showCountry: showCountry,
                        onSuccess: onSuccess,
                        onCancel: onCancel,
                        onFailure: onFailure
                    )
                    .frame(width: 0, height: 0)
                )
        }
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview {
    NavigationStack {
        SwiftUIDemoView()
    }
}

// MARK: - Modal Presentation Bridge

/// Bridge to present PaymentSheet as a modal using UIKit
@available(iOS 13.0, *)
private struct PaymentSheetModalBridge: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let credentials: FinixCredentials
    let configuration: PaymentInputController.Configuration
    let style: PaymentInputController.Style
    let theme: any ColorThemeProtocol
    let showCancelButton: Bool
    let showCancelItem: Bool
    let showCountry: Bool
    let onSuccess: (TokenResponse) -> Void
    let onCancel: () -> Void
    let onFailure: (Error) -> Void

    func makeUIViewController(context: Context) -> ModalBridgeViewController {
        let controller = ModalBridgeViewController()
        controller.credentials = credentials
        controller.configuration = configuration
        controller.style = style
        controller.theme = theme
        controller.showCancelButton = showCancelButton
        controller.showCancelItem = showCancelItem
        controller.showCountry = showCountry
        controller.onSuccess = onSuccess
        controller.onCancel = onCancel
        controller.onFailure = onFailure
        controller.onDismiss = {
            DispatchQueue.main.async {
                context.coordinator.parent.isPresented = false
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: ModalBridgeViewController, context _: Context) {
        if isPresented, !uiViewController.isModalPresented {
            uiViewController.presentModal()
        } else if !isPresented, uiViewController.isModalPresented {
            uiViewController.dismissModal()
        }
    }

    class Coordinator {
        var parent: PaymentSheetModalBridge

        init(_ parent: PaymentSheetModalBridge) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

@available(iOS 13.0, *)
private class ModalBridgeViewController: UIViewController {
    var credentials: FinixCredentials!
    var configuration: PaymentInputController.Configuration!
    var style: PaymentInputController.Style!
    var theme: (any ColorThemeProtocol)!
    var showCancelButton: Bool = false
    var showCancelItem: Bool = true
    var showCountry: Bool = false

    var onSuccess: ((TokenResponse) -> Void)?
    var onCancel: (() -> Void)?
    var onFailure: ((Error) -> Void)?
    var onDismiss: (() -> Void)?

    private(set) var isModalPresented = false
    private var paymentSDK: PaymentAction?

    func presentModal() {
        guard !isModalPresented else { return }

        let paymentSDK = PaymentAction(credentials: credentials, configuration: configuration)
        paymentSDK.delegate = self
        self.paymentSDK = paymentSDK

        let paymentSheet = paymentSDK.paymentSheet(
            style: style,
            theme: theme,
            showCancelButton: showCancelButton,
            showCancelItem: true, // Always show close button for modal presentation
            showCountry: showCountry
        )

        paymentSheet.delegate = self

        // Present modally using UIKit method
        paymentSDK.present(from: self, paymentSheet: paymentSheet, animated: true)
        isModalPresented = true
    }

    func dismissModal() {
        guard isModalPresented else { return }
        dismiss(animated: true)
        isModalPresented = false
        paymentSDK = nil
    }
}

@available(iOS 13.0, *)
extension ModalBridgeViewController: PaymentActionDelegate {
    func didSucceed(paymentController _: PaymentInputController, instrument: TokenResponse) {
        isModalPresented = false
        paymentSDK = nil
        onDismiss?()

        DispatchQueue.main.async { [weak self] in
            self?.onSuccess?(instrument)
        }
    }

    func didCancel(paymentController _: PaymentInputController) {
        isModalPresented = false
        paymentSDK = nil
        onDismiss?()
        onCancel?()
    }

    func didFail(paymentController _: PaymentInputController, error: Error) {
        isModalPresented = false
        paymentSDK = nil
        onDismiss?()
        onFailure?(error)
    }
}

// MARK: - UIKit Wrapper for Demo Navigation

/// UIKit wrapper to present SwiftUI demo from demo app navigation
@available(iOS 15.0, *)
class SwiftUIDemoViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        title = "SwiftUI Demo"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Don't wrap in NavigationView since we're already in a UINavigationController
        // This avoids double navigation bars
        let swiftUIView = SwiftUIDemoView()

        let hostingController = UIHostingController(rootView: swiftUIView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)
    }
}
