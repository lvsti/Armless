//
//  ContentView.swift
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 02..
//

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
}

class ViewModel: DropDelegate {
    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [kUTTypeFileURL as String]).first else { return false }

        provider.loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil) { [weak self] data, error in
            guard let self = self else { return }
            if let data = data as? Data, let str = String(data: data, encoding: .utf8) {
                let url = URL(fileURLWithPath: str).standardized
                let results = self.scanForBinaries(at: url)
                print("\(results)")
            }
        }
        return true
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
                          armSliceSize: sizeOfARM64SliceInBinary(at: url))
    }

    private func sizeOfARM64SliceInBinary(at url: URL) -> Int? {
        guard let reader = MachOReader(url: url), reader.isFatBinary, reader.hasARM64 else { return nil }
        return Int(reader.arm64Size)
    }
}

struct DropView: View {
    let viewModel = ViewModel()

    var body: some View {
        Text("Drop files")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [kUTTypeFileURL as String], delegate: viewModel)
    }
}


struct DropView_Previews: PreviewProvider {
    static var previews: some View {
        DropView()
    }
}
