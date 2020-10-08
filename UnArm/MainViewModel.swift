//
//  MainViewModel.swift
//  UnArm
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
    let originalSize: Int
    let armSliceSize: Int?
    var isProcessing: Bool
    let icon: NSImage
}

extension ScanResult: Identifiable {
    var id: URL { url }
}

struct MainViewState {
    var scanResults: [ScanResult]
    var selectedIndices: IndexSet
    var isProcessing: Bool
}

enum MainViewInput {
    case didReceiveDrop(info: DropInfo)
    case didPressDisarmButton
    case didSelectRow(index: Int)
    case didDeselectRow(index: Int)
    case clearList
}


class MainViewModel: ViewModel {
    @Published private(set) var state: MainViewState = MainViewState(scanResults: [], selectedIndices: [], isProcessing: false)

    func trigger(_ input: MainViewInput) {
        switch input {
        case .didReceiveDrop(let info):
            handleDrop(info)
        case .didPressDisarmButton:
            disarmSelectedBinaries()
        case .didSelectRow(let index): break
        case .didDeselectRow(let index): break
        case .clearList:
            break
        }
    }

    private func handleDrop(_ info: DropInfo) {
        guard let provider = info.itemProviders(for: [kUTTypeFileURL as String]).first else { return }

        provider.loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil) { [weak self] data, error in
            guard let self = self else { return }
            if let data = data as? Data, let str = String(data: data, encoding: .utf8) {
                let url = URL(fileURLWithPath: str).standardized
                let results = self.scanForBinaries(at: url)
                DispatchQueue.main.async {
                    self.updateResults(with: results)
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

        var results: [ScanResult] = []
        if let etor = FileManager.default.enumerator(at: url,
                                                     includingPropertiesForKeys: [.isRegularFileKey, .isExecutableKey, .isWritableKey, .fileSizeKey],
                                                     options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]) {
            while let obj = etor.nextObject() {
                guard let suburl = obj as? URL else { continue }
                results.append(contentsOf: scanForBinaries(at: suburl))
            }
        }
        return results
    }

    private func analyzeFile(at url: URL) -> ScanResult? {
        guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isExecutableKey, .isWritableKey, .volumeIsReadOnlyKey, .fileSizeKey]),
              values.isExecutable! && values.isRegularFile!
        else { return nil }

        return ScanResult(url: url,
                          writableStatus: values.volumeIsReadOnly! ? .readOnlyVolume : values.isWritable! ? .writable : .writableAsAdmin,
                          originalSize: values.fileSize!,
                          armSliceSize: sizeOfARM64SliceInBinary(at: url),
                          isProcessing: false,
                          icon: icon(forFileAt: url))
    }

    private func sizeOfARM64SliceInBinary(at url: URL) -> Int? {
        guard let reader = MachOReader(url: url), reader.isFatBinary, reader.hasARM64 else { return nil }
        return Int(reader.arm64Size)
    }

    private func icon(forFileAt url: URL) -> NSImage {
        let comps = url.pathComponents

        if comps.count >= 3, comps.suffix(3).dropLast() == ["Contents", "MacOS"] {
            return NSWorkspace.shared.icon(forFile: url.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path)
        }

        return NSWorkspace.shared.icon(forFile: url.path)
    }

    private func updateResults(with newResults: [ScanResult]) {
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

        state.scanResults.sort(by: { $0.url.path < $1.url.path })
    }

    private func disarmSelectedBinaries() {
        state.isProcessing = true
        let binariesToDisarm = state.scanResults.enumerated().filter { state.selectedIndices.contains($0.offset) }.map { $0.element }

        DispatchQueue.global(qos: .userInitiated).async {
            for binary in binariesToDisarm {
                var processingBinary = binary
                processingBinary.isProcessing = true
                DispatchQueue.main.async {
                    self.updateResults(with: [processingBinary])
                }
                if self.disarmBinary(at: binary.url), let processedBinary = self.analyzeFile(at: binary.url) {
                    DispatchQueue.main.async {
                        self.updateResults(with: [processedBinary])
                    }
                }
            }
            DispatchQueue.main.async {
                self.state.isProcessing = false
            }
        }
    }

    private func disarmBinary(at url: URL) -> Bool {
        do {
            let strippedURL = url.appendingPathExtension("disarmed")
            let lipo = try Process.run(URL(fileURLWithPath: "/usr/bin/lipo"),
                                       arguments: ["-remove", "arm64", "-output", strippedURL.path, url.path])
            lipo.waitUntilExit()

            guard lipo.terminationStatus == 0 else {
                return false
            }

            try FileManager.default.removeItem(at: url)
            try FileManager.default.moveItem(at: strippedURL, to: url)
        }
        catch {
            return false
        }

        return true
    }
}
