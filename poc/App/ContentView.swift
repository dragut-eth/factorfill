import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("What this is") {
                    Text("A proof-of-concept authenticator that offers the code **123456** to any app or website that asks for a one-time verification code.")
                }
                Section("How to enable it") {
                    Label("Open Settings → General → AutoFill & Passwords", systemImage: "1.circle")
                    Label("Turn on \"AutoFill Passwords and Passcodes\"", systemImage: "2.circle")
                    Label("Under \"Verification Codes\", enable \"AutofillPOC\"", systemImage: "3.circle")
                }
                Section("Then try it") {
                    Label("Open Safari on a site with a one-time code field", systemImage: "safari")
                    Label("Tap the code field — pick the QuickType suggestion or the AutoFill key", systemImage: "keyboard")
                    Label("Choose \"AutofillPOC\" → tap Fill code 123456", systemImage: "checkmark.seal")
                }
            }
            .navigationTitle("Autofill POC")
        }
    }
}

#Preview {
    ContentView()
}
