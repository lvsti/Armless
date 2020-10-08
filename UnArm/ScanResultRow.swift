//
//  ScanResultRow.swift
//  UnArm
//
//  Created by Tamas Lustyik on 2020. 10. 03..
//

import SwiftUI

struct ScanResultRow: View {
    var scanResult: ScanResult
    
    var body: some View {
        HStack {
            Image(nsImage: scanResult.icon)
            VStack(alignment: .leading, spacing: 4) {
                Text(scanResult.url.path)
                    .font(.system(size: 14.0, weight: .bold, design: .default))
                Text(scanResult.url.path)
                    .font(.system(size: 10.0, weight: .regular, design: .default))
            }

            Spacer()
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
    }
}

struct ScanResultRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScanResultRow(scanResult: ScanResult(url: URL(fileURLWithPath: "/Applications/Dictionary.app/Contents/Dictionary"),
                                                 writableStatus: .writable,
                                                 originalSize: 100,
                                                 armSliceSize: nil,
                                                 isProcessing: false,
                                                 icon: NSImage()))
            ScanResultRow(scanResult: ScanResult(url: URL(fileURLWithPath: "/Applications/Dictionary.app/Contents/Dictionary"),
                                                 writableStatus: .writable,
                                                 originalSize: 100,
                                                 armSliceSize: nil,
                                                 isProcessing: true,
                                                 icon: NSImage()))
        }
    }
}
