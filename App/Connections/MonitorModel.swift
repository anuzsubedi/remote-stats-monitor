import SwiftUI
import WidgetKit
import ServiceManagement

@MainActor @Observable
final class MonitorModel {
    var sessions: [ServerSession] = []
    var selectedID: UUID?
    var draft = Connection()
    var error: String?
    var isConnecting = false
    var successfulConnectionCount = 0
    var keyProposal: HostKeyProposal?
    var showHostKeyPrompt = false
    var launchesAtLogin = SMAppService.mainApp.status == .enabled
    var sampleSnapshot: MonitorSnapshot?
    @ObservationIgnored private var pendingConnection: Connection?
    @ObservationIgnored private let connectionSSH = SSHService()
    @ObservationIgnored private var lastWidgetReload = Date.distantPast

    var selectedSession: ServerSession? { sessions.first { $0.id == selectedID } }
    var connection: Connection? { selectedSession?.connection }
    var snapshot: MonitorSnapshot? { selectedSession?.snapshot ?? (sessions.isEmpty ? sampleSnapshot : nil) }
    var isRefreshing: Bool { selectedSession?.isRefreshing ?? false }
    var menuBarTitle: String {
        guard let snapshot, !snapshot.isStale(), snapshot.connectionError == nil else { return "Remote Stats" }
        return "\(Int(snapshot.cpu))% CPU"
    }

    var helperURL: URL? { Bundle.main.executableURL }

    init(preview: Bool = false) {
        if preview { sampleSnapshot = .sample; return }
        do {
            let loaded = try KeychainStore.loadAll()
            var unique: [Connection] = []
            var aliases: [UUID: UUID] = [:]
            for connection in loaded {
                if let existing = unique.first(where: { $0.hasSameSettings(as: connection) }) {
                    aliases[connection.id] = existing.id
                } else { unique.append(connection) }
            }
            // Update redirects before deleting redundant credentials; retries are safe.
            sessions = unique.map { ServerSession(connection: $0) }
            do {
                try SnapshotStore.reconcile(unique.map { .init(id: $0.id, name: $0.displayName) }, aliases: aliases)
                for duplicate in aliases.keys {
                    do { try KeychainStore.delete(id: duplicate) }
                    catch { self.error = "A redundant saved login could not be removed. " + error.localizedDescription }
                }
            } catch { self.error = error.localizedDescription }
            let previousSelection = UserDefaults.standard.string(forKey: "selectedServer").flatMap(UUID.init(uuidString:))
            let saved = previousSelection.map { aliases[$0] ?? $0 }
            selectedID = sessions.first(where: { $0.id == saved })?.id ?? sessions.first?.id
            if let selectedID { UserDefaults.standard.set(selectedID.uuidString, forKey: "selectedServer") }
            for session in sessions {
                session.snapshot = SnapshotStore.read(for: session.id)
                do { try SnapshotStore.upsertServer(id: session.id, name: session.connection.displayName) }
                catch { self.error = error.localizedDescription }
                startPolling(session)
            }
            publishSelection()
            draft = connection ?? Connection()
        } catch { self.error = error.localizedDescription }
        #if DEBUG
        restoreSyntheticServers()
        #endif
    }

    func select(_ id: UUID) {
        selectedID = id
        guard selectedSession?.isSynthetic != true else { return }
        UserDefaults.standard.set(id.uuidString, forKey: "selectedServer")
        publishSelection()
    }

    func editSelected() { draft = selectedSession?.isSynthetic == true ? Connection() : connection ?? Connection(); error = nil }
    func addServer() { draft = Connection(); error = nil }

    func beginConnection() async {
        guard !isConnecting else { return }
        if let validation = draft.validationError { error = validation; return }
        isConnecting = true
        error = nil
        if let existing = sessions.first(where: { !$0.isSynthetic && $0.connection.endpointKey == draft.endpointKey && $0.id != draft.id }) {
            if sessions.contains(where: { $0.id == draft.id }) {
                error = "This destination already exists. Edit its saved connection instead."
                isConnecting = false
                return
            }
            draft.id = existing.id
        }
        pendingConnection = draft
        do {
            if let proposal = try await connectionSSH.proposedKey(for: draft) {
                keyProposal = proposal
                showHostKeyPrompt = true
                isConnecting = false
            } else { await saveAndConnect(draft) }
        } catch { self.error = error.localizedDescription; isConnecting = false }
    }

    func trustAndConnect() async {
        guard let proposal = keyProposal, let pendingConnection else { return }
        keyProposal = nil
        isConnecting = true
        do { try await connectionSSH.trust(proposal); await saveAndConnect(pendingConnection) }
        catch { self.error = error.localizedDescription; isConnecting = false }
    }

    func cancelTrust() { keyProposal = nil; showHostKeyPrompt = false; pendingConnection = nil; isConnecting = false }

    private func saveAndConnect(_ newConnection: Connection) async {
        let old = sessions.first(where: { $0.id == newConnection.id })
        if let old {
            old.generation += 1
            old.pollTask?.cancel()
            await old.ssh.close(old.connection)
        }
        do {
            try KeychainStore.save(newConnection)
            let session = ServerSession(connection: newConnection)
            if let index = sessions.firstIndex(where: { $0.id == newConnection.id }) {
                sessions[index] = session
                do { try SnapshotStore.remove(id: session.id) }
                catch { self.error = error.localizedDescription }
            } else { sessions.append(session) }
            do { try SnapshotStore.upsertServer(id: session.id, name: newConnection.displayName) }
            catch { self.error = error.localizedDescription }
            select(session.id)
            sampleSnapshot = nil
            await refresh(session)
            if session.snapshot != nil && session.error == nil {
                successfulConnectionCount += 1
            }
            if !session.authenticationFailed { startPolling(session, immediately: false) }
        } catch {
            self.error = error.localizedDescription
            if let old { startPolling(old) }
        }
        isConnecting = false
        pendingConnection = nil
    }

    func refresh() async {
        guard let selectedID else { return }
        await refreshServer(id: selectedID)
    }

    func refreshServer(id: UUID) async {
        guard let session = sessions.first(where: { $0.id == id }) else { return }
        #if DEBUG
        if session.isSynthetic { updateSyntheticReadings(); return }
        #endif
        session.authenticationFailed = false
        await refresh(session)
        if !session.authenticationFailed, sessions.contains(where: { $0.id == session.id }) { startPolling(session, immediately: false) }
    }

    private func refresh(_ session: ServerSession) async {
        guard !session.isRefreshing, let helperURL else { return }
        session.isRefreshing = true
        let generation = session.generation
        defer { session.isRefreshing = false }
        do {
            let reading = try await session.ssh.collect(session.connection, helperURL: helperURL)
            guard generation == session.generation, !Task.isCancelled else { return }
            let wasDisconnected = session.error != nil
            session.snapshot = reading
            session.error = nil
            session.authenticationFailed = false
            do { try publish(session, forceReload: wasDisconnected) }
            catch { self.error = error.localizedDescription }
        } catch {
            guard generation == session.generation, !Task.isCancelled else { return }
            session.error = error.localizedDescription
            if case MonitorError.authentication = error { session.authenticationFailed = true }
            if var last = session.snapshot {
                let changed = last.connectionError == nil
                last.connectionError = error.localizedDescription
                session.snapshot = last
                do { try publish(session, forceReload: changed) } catch { self.error = error.localizedDescription }
            }
        }
    }

    private func startPolling(_ session: ServerSession, immediately: Bool = true) {
        session.pollTask?.cancel()
        session.pollTask = Task { [weak self, weak session] in
            if !immediately {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
            }
            while !Task.isCancelled {
                guard let self, let session, !session.authenticationFailed else { return }
                await self.refresh(session)
                do { try await Task.sleep(for: .seconds(5)) } catch { break }
            }
        }
    }

    private func publish(_ session: ServerSession, forceReload: Bool) throws {
        guard let reading = session.snapshot else { return }
        try SnapshotStore.write(reading, for: session.id, name: session.connection.displayName)
        if forceReload || Date.now.timeIntervalSince(lastWidgetReload) >= 60 {
            WidgetCenter.shared.reloadAllTimelines()
            lastWidgetReload = .now
        }
    }

    private func publishSelection() {
        do {
            if let selectedID, selectedSession?.isSynthetic != true { try SnapshotStore.select(id: selectedID) }
            WidgetCenter.shared.reloadAllTimelines()
        } catch { self.error = error.localizedDescription }
    }

    func forgetConnection() async {
        guard !isConnecting, let session = sessions.first(where: { $0.id == draft.id }) else { return }
        isConnecting = true
        defer { isConnecting = false }
        do {
            try KeychainStore.delete(id: session.id)
            session.generation += 1
            session.pollTask?.cancel()
            sessions.removeAll { $0.id == session.id }
            do { try SnapshotStore.remove(id: session.id) }
            catch { self.error = error.localizedDescription }
            if selectedID == session.id { selectedID = sessions.first?.id }
            draft = connection ?? Connection()
            await session.ssh.close(session.connection)
            publishSelection()
            WidgetCenter.shared.reloadAllTimelines()
        } catch { self.error = error.localizedDescription }
    }

    func previewSample() {
        guard sessions.isEmpty else { return }
        sampleSnapshot = sampleSnapshot == nil ? .sample : nil
    }

    func setLaunchAtLogin() {
        do {
            if launchesAtLogin { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            self.error = error.localizedDescription
            launchesAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
