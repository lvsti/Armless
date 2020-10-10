//
//  ScanResultRow.swift
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 03..
//

import AppKit
import SwiftUI

struct ScanResultRow: View {
    var scanResult: ScanResult
    
    var body: some View {
        HStack {
            Image(nsImage: scanResult.icon)
            VStack(alignment: .leading, spacing: 4) {
                Text(scanResult.url.lastPathComponent)
                    .font(.system(size: 14.0, weight: .bold, design: .default))
                Text(scanResult.url.path)
                    .font(.system(size: 10.0, weight: .regular, design: .default))
                    .truncationMode(.middle)
            }
            Spacer(minLength: 20)
            Text(sliceArchNames)
                .font(.system(size: 10.0, weight: .regular, design: .default))
                .frame(width: 50, height: nil, alignment: .center)
            Image(nsImage: statusIcon)
        }
        .opacity(isEligible ? 1.0 : 0.7)
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        .contextMenu {
            Button(action: {
                NSWorkspace.shared.activateFileViewerSelecting([scanResult.url])
            }) {
                Text("Reveal in Finder")
            }
        }
    }

    private var sliceArchNames: String {
        return scanResult.slices
            .map {
                switch $0.key {
                case .ppc: return "PPC"
                case .ppc64: return "PPC64"
                case .i386: return "i386"
                case .x86_64: return "x86_64"
                case .armV6: return "ARMv6"
                case .armV7: return "ARMv7"
                case .armV7s: return "ARMv7s"
                case .arm64: return "ARM64"
                default: return "unknown"
                }
            }
            .sorted()
            .joined(separator: "\n")
    }

    private var statusIcon: NSImage {
        guard isEligible else { return NSImage(named: NSImage.statusNoneName)! }

        switch scanResult.writableStatus {
        case .readOnlyVolume: return NSImage(named: NSImage.statusUnavailableName)!
        case .writableAsAdmin: return NSImage(named: NSImage.statusPartiallyAvailableName)!
        case .writable: return NSImage(named: NSImage.statusAvailableName)!
        }
    }

    private var isEligible: Bool {
        return scanResult.isFatBinary && scanResult.slices.count > 1
    }
}

struct ScanResultRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScanResultRow(scanResult: ScanResult(url: URL(fileURLWithPath: "/Applications/Dictionary.app/Contents/Dictionary"),
                                                 writableStatus: .writable,
                                                 isFatBinary: false,
                                                 slices: [:],
                                                 originalSize: 100,
                                                 isProcessing: false,
                                                 icon: NSImage()))
            ScanResultRow(scanResult: ScanResult(url: URL(fileURLWithPath: "/Applications/Dictionary.app/Contents/Dictionary"),
                                                 writableStatus: .writable,
                                                 isFatBinary: false,
                                                 slices: [:],
                                                 originalSize: 100,
                                                 isProcessing: true,
                                                 icon: NSImage()))
        }
    }
}
