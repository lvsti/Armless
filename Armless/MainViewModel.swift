//
//  MainViewModel.swift
//  Armless
//
//  Created by Tamas Lustyik on 2020. 10. 05..
//

import Foundation
import SwiftUI

struct ScanResult {
    enum WritableStatus {
        case writable
        case writableAsAdmin
        case readOnlyVolume
    }

    let url: URL
    let writableStatus: WritableStatus
    let isFatBinary: Bool
    let slices: [SliceType: Int64]
    let originalSize: Int64
    var isProcessing: Bool
    let icon: NSImage

    var isThinnable: Bool {
        isFatBinary && slices.count > 1
    }
    var isEligible: Bool {
        isThinnable && writableStatus != .readOnlyVolume
    }
}

extension ScanResult: Identifiable {
    var id: URL { url }
}

struct MainViewState {
    var scanResults: [ScanResult]
    var selectedIDs: Set<ScanResult.ID>
    var sliceTypeForCurrentArch: SliceType
    var isScanning: Bool
    var processingProgress: Progress?

    var isProcessing: Bool {
        processingProgress != nil
    }
    var isClearButtonEnabled: Bool {
        !isProcessing && !scanResults.isEmpty
    }
    var isStartButtonEnabled: Bool {
        !isProcessing && scanResults.contains(where: { $0.isEligible })
    }
    var statusText: String {
        guard !scanResults.isEmpty else { return "No files" }

        let (eligibleCount, originalSize, reducedSize) = scanResults.reduce((0, Int64(0), Int64(0))) { acc, next in
            guard next.slices.count > 1 else { return acc }
            let savings = next.slices.reduce(Int64(0)) { acc, next in acc + next.value } - next.slices[sliceTypeForCurrentArch]!
            return (acc.0 + 1, acc.1 + next.originalSize, acc.2 + savings)
        }

        return "Estimated savings: \(Self.sizeFormatter.string(fromByteCount: originalSize - reducedSize)) " +
            "of \(Self.sizeFormatter.string(fromByteCount: originalSize)) in \(eligibleCount) binaries"
    }

    private static let sizeFormatter: ByteCountFormatter = {
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        return fmt
    }()
}

enum MainViewInput {
    case didReceiveDrop(info: DropInfo)
    case didPressClearListButton
    case didPressStartButton
    case didChangeSelection(selectedIDs: Set<ScanResult.ID>)
    case didPressDeleteOnList
}

extension SliceType {
    var archName: String? {
        switch self {
        case .x86_64: return "x86_64"
        case .arm64: return "arm64"
        default: return nil
        }
    }
}

class MainViewModel: ViewModel {
    private static let sliceTypeForCurrentArch: SliceType = SystemInfo.cpuType == .arm64 ? .arm64 : .x86_64

    @Published private(set) var state: MainViewState = MainViewState(scanResults: [],
                                                                     selectedIDs: [],
                                                                     sliceTypeForCurrentArch: sliceTypeForCurrentArch,
                                                                     isScanning: false)

    private var scanResultIndices: [ScanResult.ID: Int] = [:]

    func trigger(_ input: MainViewInput) {
        switch input {
        case .didReceiveDrop(let info):
            handleDrop(info)
        case .didPressClearListButton:
            state.scanResults.removeAll()
            state.selectedIDs.removeAll()
            scanResultIndices.removeAll()
        case .didPressStartButton:
            thinBinaries()
        case .didChangeSelection(let ids):
            let validIDs = ids
                .filter {
                    guard let index = scanResultIndices[$0] else { return false }
                    return !state.scanResults[index].isProcessing
                }
            state.selectedIDs = validIDs
        case .didPressDeleteOnList:
            guard !state.selectedIDs.isEmpty else { break }
            state.scanResults = state.scanResults.filter { !state.selectedIDs.contains($0.id) }
            state.selectedIDs.removeAll()
            scanResultIndices = Dictionary(state.scanResults.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { $1 })
        }
    }

    private func handleDrop(_ info: DropInfo) {
        guard !state.isProcessing else { return }

        let providers = info.itemProviders(for: [kUTTypeFileURL as String])
        guard !providers.isEmpty else { return }

        state.isScanning = true
        var remaining = providers.count

        for provider in providers {
            provider.loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil) { data, error in
                defer {
                    DispatchQueue.main.async {
                        remaining -= 1
                        if remaining == 0 {
                            self.state.isScanning = false
                        }
                    }
                }
                if let data = data as? Data, let str = String(data: data, encoding: .utf8) {
                    let url = URL(fileURLWithPath: str).standardized
                    let results = self.scanForBinaries(at: url)
                    DispatchQueue.main.async {
                        self.updateResults(with: results)
                    }
                }
            }
        }
    }

    private func scanForBinaries(at url: URL) -> [ScanResult] {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return [] }

        guard isDir.boolValue else {
            if let result = analyzeFile(at: url) {
                return [result]
            }
            return []
        }

        guard let etor = FileManager.default.enumerator(at: url,
                                                        includingPropertiesForKeys: [.isRegularFileKey, .isExecutableKey, .isWritableKey, .fileSizeKey],
                                                        options: [.skipsHiddenFiles]) else {
            return []
        }

        var results: [ScanResult] = []
        while let obj = etor.nextObject() {
            guard let suburl = obj as? URL else { continue }
            guard FileManager.default.fileExists(atPath: suburl.path, isDirectory: &isDir) else { continue }

            if !isDir.boolValue, let result = analyzeFile(at: suburl) {
                results.append(result)
            }
        }
        return results
    }

    private func analyzeFile(at url: URL) -> ScanResult? {
        guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isExecutableKey, .isWritableKey, .volumeIsReadOnlyKey, .fileSizeKey]),
              values.isExecutable! && values.isRegularFile!
        else { return nil }

        guard let reader = MachOReader(url: url), reader.slices[NSNumber(value: Self.sliceTypeForCurrentArch.rawValue)] != nil else { return nil }
        return ScanResult(url: url,
                          writableStatus: values.volumeIsReadOnly! ? .readOnlyVolume : values.isWritable! ? .writable : .writableAsAdmin,
                          isFatBinary: reader.isFatBinary,
                          slices: Dictionary(reader.slices.map { (SliceType(rawValue: $0.uintValue)!, Int64($1.int64Value)) }, uniquingKeysWith: { $1 }),
                          originalSize: Int64(values.fileSize!),
                          isProcessing: false,
                          icon: icon(forFileAt: url))
    }

    private func icon(forFileAt url: URL) -> NSImage {
        let comps = url.pathComponents

        if comps.count >= 3, comps.suffix(3).dropLast() == ["Contents", "MacOS"] {
            return NSWorkspace.shared.icon(forFile: url.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path)
        }

        return NSWorkspace.shared.icon(forFile: url.path)
    }

    private func updateResults(with newResults: [ScanResult]) {
        defer {
            scanResultIndices = Dictionary(state.scanResults.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { $1 })
        }

        if state.scanResults.isEmpty {
            state.scanResults = newResults
            return
        }

        let keyValues = state.scanResults.enumerated().map { ($0.element.url, $0.offset) }
        let resultMap = Dictionary(keyValues, uniquingKeysWith: { $1 })

        for newResult in newResults {
            if let oldResultIndex = resultMap[newResult.url] {
                state.scanResults[oldResultIndex] = newResult
            } else {
                state.scanResults.append(newResult)
            }
        }
    }

    private func thinBinaries() {
        guard !state.isProcessing else { return }

        let binariesToThin = state.scanResults.filter { $0.writableStatus != .readOnlyVolume && $0.slices.contains(where: { $0.key != Self.sliceTypeForCurrentArch }) }
        guard !binariesToThin.isEmpty else { return }

        state.processingProgress = Progress(totalUnitCount: Int64(binariesToThin.count))

        DispatchQueue.global(qos: .userInitiated).async {
            for var binary in binariesToThin {
                binary.isProcessing = true
                DispatchQueue.main.async {
                    self.state.processingProgress?.completedUnitCount += 1
                    self.updateResults(with: [binary])
                }

                if self.thinBinary(at: binary.url), let processedBinary = self.analyzeFile(at: binary.url) {
                    binary = processedBinary
                }

                binary.isProcessing = false
                DispatchQueue.main.async {
                    self.updateResults(with: [binary])
                }
            }
            DispatchQueue.main.async {
                self.state.processingProgress = nil
            }
        }
    }

    private func thinBinary(at url: URL) -> Bool {
        do {
            let thinnedURL = url.appendingPathExtension("thinned")
            let lipo = try Process.run(URL(fileURLWithPath: "/usr/bin/lipo"),
                                       arguments: ["-thin", Self.sliceTypeForCurrentArch.archName!, "-output", thinnedURL.path, url.path])
            lipo.waitUntilExit()

            guard lipo.terminationStatus == 0 else {
                return false
            }

            try FileManager.default.removeItem(at: url)
            try FileManager.default.moveItem(at: thinnedURL, to: url)
        }
        catch {
            return false
        }

        return true
    }
}
