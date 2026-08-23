import AuthenticationServices
import AppKit

/// macOS AutoFill credential-provider extension that always vends the one-time code "123456".
class CredentialProviderViewController: ASCredentialProviderViewController {

    private let code = "123456"

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 220))
    }

    // Called when the user activates AutoFill on a one-time-code field and picks this provider.
    override func prepareOneTimeCodeCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        buildUI(service: serviceIdentifiers.first?.identifier)
    }

    override func prepareInterfaceForExtensionConfiguration() {
        buildUI(service: nil)
    }

    private func buildUI(service: String?) {
        view.subviews.forEach { $0.removeFromSuperview() }

        let title = NSTextField(labelWithString: "POC Authenticator")
        title.font = .boldSystemFont(ofSize: 18)
        title.alignment = .center

        let subtitle = NSTextField(labelWithString: service.map { "Verification code for \($0)" } ?? "Verification code")
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .center
        subtitle.lineBreakMode = .byTruncatingTail

        let button = NSButton(title: "Fill code \(code)", target: self, action: #selector(fill))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelRequest))
        cancelButton.bezelStyle = .rounded

        let stack = NSStackView(views: [title, subtitle, button, cancelButton])
        stack.orientation = .vertical
        stack.spacing = 16
        stack.alignment = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
        ])
    }

    @objc private func fill() {
        let credential = ASOneTimeCodeCredential(code: code)
        extensionContext.completeOneTimeCodeRequest(withSelectedCredential: credential, completionHandler: nil)
    }

    @objc private func cancelRequest() {
        extensionContext.cancelRequest(
            withError: NSError(domain: ASExtensionErrorDomain,
                               code: ASExtensionError.userCanceled.rawValue)
        )
    }
}
