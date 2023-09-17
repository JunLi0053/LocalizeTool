//
//  ContentView.swift
//  LocalizeTool
//
//  Created by Jun on 2023/9/10.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreXLSX


struct ContentView: View {
    @State var image = NSImage(named: "")
    @State private var dragOver = false
    @State private var importing = false
    @State var languages = [String: String]()
    var body: some View {
        HStack(spacing: 1) {
            GeometryReader {geo in
                Image("folder.fill.badge.plus")
                    .onTapGesture {
                        importing = true
                    }
                    .position(x: geo.size.width/2, y:geo.size.height/2)
//                                    .fileImporter(
//                                        isPresented: $importing,
//                                        allowedContentTypes: [.plainText, UTType("com.microsoft.excel.xls")!]
//                                    ) { result in
//                                        switch result {
//                                        case .success(let file):
//                                            languages = handle(fileURL: file)
//                
//                                        case .failure(let error):
//                                            print(error.localizedDescription)
//                                        }
//                                    }
                
            }.onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                    if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                        languages = handle(fileURL: url)
                    }
                })
                return true
            }
            .onDrag {
                let provider =  NSItemProvider()
                return provider
            }
            .frame(width: 200)
            
            Divider().background(Color.black)
            
            GeometryReader { geo in
                NavList(languages: languages)
            }
            
        }
        
    }
}

struct NavList : View {
    var languages = [String: String]()
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(languages.keys), id: \.self){key in
                    NavigationLink(destination: LocateView(content: languages[key]!)
                        .navigationTitle(key)){
                            Text(key).font(.title3)
                        }
                }
            }
        }
        .listStyle(SidebarListStyle())
        
    }
}

func handle(fileURL : URL) -> [String: String]{
    var dict = [String: String]()
    guard let file = XLSXFile(filepath: fileURL.absoluteString.replacingOccurrences(of: "file://", with: "")) else {
        print("XLSXFile......")
        return dict
    }
    
    
    for path in try! file.parseWorksheetPaths() {
        
        let ws = try! file.parseWorksheet(at: path)
        if let sharedStrings = try! file.parseSharedStrings() {
            var lines = [[String]]()
            for row in ws.data?.rows ?? [] {
                let line = ws.cells(atRows: [row.reference]).compactMap{$0.stringValue(sharedStrings)}
                lines.append(line)
            }
            
            let csv = CSV(lines: lines)
            let languages = csv.headers.filter { header in
                header != "Key"
            }
            languages.forEach { language in
                let languageLoc = csv.columns[language]
                let keys = csv.columns["Key"]
                var localeContent = ""
                for i in 0..<keys!.count {
                    localeContent = localeContent +
                    "\"\(keys![i])\" = \"\(languageLoc![i])\"" + "\n"
                }
                dict[language] = localeContent
            }
        }
    }
    
    
    
    return dict
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        
    }
    
}
