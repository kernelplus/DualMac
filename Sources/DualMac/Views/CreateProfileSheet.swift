import SwiftUI

public struct CreateProfileSheet: View {
    public let app: InstalledApp
    public let onCreated: (DualProfile) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var profileName: String = "Dual"
    @State private var selectedMethod: CloningMethod
    @State private var useOfficialBadge: Bool = true
    @State private var badgeText: String = "D"
    @State private var selectedColorHex: String = "#2563EB" // Dual Royal Blue
    @State private var selectedShape: String = "roundedRectangle"
    @State private var isCreating: Bool = false
    @State private var errorMessage: String? = nil
    
    public init(app: InstalledApp, onCreated: @escaping (DualProfile) -> Void) {
        self.app = app
        self.onCreated = onCreated
        _selectedMethod = State(initialValue: app.recommendedMethod)
    }
    
    private var currentBadgeConfig: BadgeConfig {
        BadgeConfig(
            label: badgeText,
            colorHex: selectedColorHex,
            shape: selectedShape,
            position: "bottomRight",
            useDualIconBadge: useOfficialBadge
        )
    }
    
    private var previewImage: NSImage {
        IconBadgeService.generateBadgedImage(
            baseImage: app.icon,
            badge: currentBadgeConfig,
            targetSize: 128
        )
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create Dual Profile: \(app.name)")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile Name & Icon Preview
                    HStack(alignment: .top, spacing: 20) {
                        VStack {
                            Image(nsImage: previewImage)
                                .resizable()
                                .frame(width: 96, height: 96)
                                .shadow(radius: 3)
                            Text("Dock Preview")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Profile Name")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            TextField("e.g. Work, Personal, Client", text: $profileName)
                                .textFieldStyle(.roundedBorder)
                            
                            Text("Clone Method")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Picker("", selection: $selectedMethod) {
                                ForEach(CloningMethod.allCases) { method in
                                    Text(method.shortTitle).tag(method)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Text(selectedMethod.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    
                    // Badge Customization
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dock Badge Customization")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Toggle("Use Official Blue 'D' Badge", isOn: $useOfficialBadge)
                            .toggleStyle(.checkbox)
                        
                        if useOfficialBadge {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                Text("Dual clone icon displays the royal blue 'D' squircle badge. The original app icon remains untouched.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        } else {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text("Badge Label / Text")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("D", text: $badgeText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Badge Shape")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Picker("", selection: $selectedShape) {
                                        Text("Circle").tag("circle")
                                        Text("Rounded").tag("roundedRectangle")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 160)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Badge Tint Color")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 10) {
                                    ForEach(BadgeConfig.presetColors, id: \.self) { colorHex in
                                        Circle()
                                            .fill(Color(nsColor: IconBadgeService.color(fromHex: colorHex)))
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColorHex == colorHex ? 2.5 : 0)
                                            )
                                            .shadow(radius: selectedColorHex == colorHex ? 2 : 0)
                                            .onTapGesture {
                                                selectedColorHex = colorHex
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    
                    // Warnings & Info Box
                    if selectedMethod == .bundleDuplicate {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Method B Note: Static Bundle Duplicate")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                Text("This clone will be placed in ~/Applications/DualMac. Notice: Method B clones are independent copies and do not receive updates when the original application in /Applications updates.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button(action: {
                    createProfile()
                }) {
                    if isCreating {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 70)
                    } else {
                        Text("Create Profile")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(profileName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 540, height: 500)
    }
    
    private func createProfile() {
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                let profile = try await CloningEngine.createProfile(
                    for: app,
                    name: profileName.trimmingCharacters(in: .whitespaces),
                    method: selectedMethod,
                    badge: currentBadgeConfig
                )
                await MainActor.run {
                    isCreating = false
                    onCreated(profile)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "Error creating profile: \(error.localizedDescription)"
                }
            }
        }
    }
}
