import CanliDuvarCore
import SwiftUI

struct WorkshopSheet: View {
    @EnvironmentObject private var workshop: WorkshopDownloader
    @Environment(\.dismiss) private var dismiss
    @State private var links = ""
    @State private var showLog = false

    private var ids: [String] { Workshop.itemIDs(in: links) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Download from Steam Workshop", systemImage: "arrow.down.circle").font(.title2.bold())
                Spacer()
                Button("Open Workshop") { NSWorkspace.shared.open(WorkshopDownloader.workshopURL) }
            }
            Text("Copy the link of a Wallpaper Engine Workshop item and paste it below. Tip: set the Workshop “Type” filter to Video or Web — Scene wallpapers can’t play on macOS.")
                .font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            step(1, done: workshop.isInstalled, title: "SteamCMD (Valve’s official download tool)") {
                if workshop.isInstalled {
                    Text(workshop.root.path).font(.caption).foregroundStyle(.secondary)
                        .lineLimit(1).truncationMode(.middle)
                } else {
                    Button("Install (about 80 MB)") { Task { await workshop.install() } }
                        .disabled(workshop.isRunning)
                }
            }

            step(2, done: !workshop.username.isEmpty && !workshop.needsLogin, title: "Steam account that owns Wallpaper Engine") {
                HStack {
                    TextField("Steam user name", text: $workshop.username)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                    Button("Sign In to Steam…") { workshop.openLoginTerminal() }
                        .disabled(workshop.username.isEmpty || !workshop.isInstalled)
                }
                Text("Needed only once. Your password and Steam Guard code are typed into Terminal and go directly to Steam — Canlı Duvar never sees or stores them.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            step(3, done: false, title: "Workshop links (one per line)") {
                TextEditor(text: $links)
                    .font(.system(.callout, design: .monospaced))
                    .frame(height: 90)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
                if ids.isEmpty {
                    Text("Example: https://steamcommunity.com/sharedfiles/filedetails/?id=1234567890")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    let list = ids.joined(separator: ", ")
                    Text("Items found: \(ids.count) — \(list)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            if let status = workshop.status {
                Text(status)
                    .font(.callout)
                    .foregroundStyle(workshop.needsLogin ? .orange : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            DisclosureGroup("Detailed log", isExpanded: $showLog) {
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(workshop.log.isEmpty ? "—" : workshop.log)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Color.clear.frame(height: 1).id("end")
                    }
                    .frame(height: 120)
                    .onChange(of: workshop.log) { _, _ in proxy.scrollTo("end") }
                }
            }

            HStack {
                if workshop.isRunning {
                    ProgressView().controlSize(.small)
                    Text("Working…").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Close") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Download and Add") {
                    Task {
                        await workshop.download(links)
                        if !workshop.needsLogin { links = "" }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(workshop.isRunning || ids.isEmpty || workshop.username.isEmpty || !workshop.isInstalled)
            }
        }
        .padding(22)
        .frame(width: 620)
    }

    @ViewBuilder
    private func step<Content: View>(_ number: Int, done: Bool, title: LocalizedStringKey,
                                     @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: done ? "checkmark.circle.fill" : "\(number).circle")
                .font(.title3)
                .foregroundStyle(done ? .green : .secondary)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                content()
            }
        }
    }
}
