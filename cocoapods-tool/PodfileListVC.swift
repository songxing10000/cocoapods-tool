//
//  PodfileVC.swift
//  cocoapods-tool
//
//  Created by dfpo on 27/01/2022.
//

import Cocoa

class PodfileListVC: NSViewController {
    private let saveKey = "podfilePaths"
    @IBOutlet weak var m_tableView: NSTableView!
    private var m_filePaths = [String]()
    @IBOutlet var outputText:NSTextView!
    
    private let nameIdentifier = NSUserInterfaceItemIdentifier("name")
    private let typeIdentifier = NSUserInterfaceItemIdentifier("type")
    private let urlIdentifier = NSUserInterfaceItemIdentifier("url")
    private let pathIdentifier = NSUserInterfaceItemIdentifier("path")
    private let actionIdentifier = NSUserInterfaceItemIdentifier("action")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        m_tableView.rowHeight = 46
        if let paths = UserDefaults.standard.object(forKey: self.saveKey) as? [String] {
            m_filePaths.append(contentsOf: paths)
            m_tableView.reloadData()
            
        }
        m_tableView.doubleAction = #selector(doubleClickOnResultRow)
        
        cellAddRightMenu()
        // 拖拽一个文件到NSTableView中，获取其路径
        m_tableView.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    // cell上右键菜单 https://www.codercto.com/a/9125.html
    private func cellAddRightMenu() {
        let menu = NSMenu()
        menu.delegate = self
        m_tableView.menu = menu
    }
    @IBAction func clickAddBtn(_ sender: NSButton) {
        guard let window = view.window else {
            return
        }
        let panel:NSOpenPanel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = true
        
        panel.beginSheetModal(for: window) { (response) in
            if response == .OK, let filePath = panel.urls.first?.path, !filePath.isEmpty {
                
                self.insertPodfile(filePath: filePath)
                self.m_tableView.reloadData()
                
                
            }
        }
    }
    private func insertPodfile(filePath: String) {
        let usde = UserDefaults.standard
        // 是文件
        if var paths = usde.object(forKey: self.saveKey) as? [String], !paths.isEmpty {
            if !paths.contains(filePath) {
                paths.append(filePath)
            }
            usde.set(paths, forKey: self.saveKey)
            self.m_filePaths.removeAll()
            self.m_filePaths.append(contentsOf:  paths)
        } else {
            usde.set([filePath], forKey: self.saveKey)
            self.m_filePaths.removeAll()
            self.m_filePaths.append(filePath)
        }
    }
    @objc func clickUpdateBtn(_ btn: NSButton) {
        let filePath = m_filePaths[btn.tag]
        Util.doPodInstallAtPath(path: filePath, outputText: outputText)
    }
    // MARK: - cell双击事件
    @objc func doubleClickOnResultRow() {
        let idx = m_tableView.selectedRow
        guard idx >= 0,
              m_tableView.clickedColumn >= 0,
              let row: NSTableRowView = m_tableView.rowView(atRow: idx, makeIfNecessary: false),
              let cellView = row.view(atColumn: m_tableView.clickedColumn) as? NSTableCellView  else {
                  return
              }
        
        if cellView.identifier == urlIdentifier {
            
            //            m_outputTextField.stringValue = "尝试打开url：\(url)"
            return
        }
        
        if cellView.identifier == pathIdentifier {
            
            //            m_outputTextField.stringValue = "尝试打开路径：\(path)"
            
            return
        }
        if cellView.identifier == nameIdentifier {
            let path = m_filePaths[idx]
            Util.openPath(path)
            return
        }
        if cellView.identifier == typeIdentifier {
            
            return
        }
    }
}
extension PodfileListVC: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else {
            return nil
        }
        
        
        var cellView: NSTableCellView?
        if identifier == nameIdentifier {
            
            cellView  =  tableView.makeView(withIdentifier: nameIdentifier, owner: self) as? NSTableCellView
            cellView?.textField?.stringValue = m_filePaths[row]
            
            return cellView
        }
        if identifier == typeIdentifier {
            cellView  =  tableView.makeView(withIdentifier: typeIdentifier, owner: self) as? NSTableCellView
            //            cellView?.textField?.stringValue = m_filePaths[row].type
            
            return cellView
        }
        if identifier == urlIdentifier {
            cellView  =  tableView.makeView(withIdentifier: urlIdentifier, owner: self) as? NSTableCellView
            //            cellView?.textField?.stringValue = m_filePaths[row].URL
            
            return cellView
        }
        if identifier == pathIdentifier {
            cellView  =  tableView.makeView(withIdentifier: pathIdentifier, owner: self) as? NSTableCellView
            //            cellView?.textField?.stringValue = m_filePaths[row].path
            
            return cellView
        }
        if identifier == actionIdentifier {
            cellView  =  tableView.makeView(withIdentifier: actionIdentifier, owner: self) as? NSTableCellView
            if let btn = cellView?.subviews.filter({$0 is NSButton}).first as? NSButton {
                btn.tag = row
                // 注意不设置target可能有时候，只有在选中这一行cell时，点按钮才会有响应
                btn.target = self
                btn.action = #selector(clickUpdateBtn)
                
            }
            return cellView
        }
        return cellView;
    }
    
}
extension PodfileListVC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        print(m_filePaths.count)
        return m_filePaths.count
    }
    // MARK: Drag Destination Actions
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if let filePath = info.draggingPasteboard.pasteboardItems?.first?.string(forType: .fileURL),
           let url = URL(string: filePath),
           url.lastPathComponent == "Podfile" {
            return .link
            
        }
        return []
    }
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        if let filePath = info.draggingPasteboard.pasteboardItems?.first?.string(forType: .fileURL),
           let url = URL(string: filePath),
           url.lastPathComponent == "Podfile" {
            self.insertPodfile(filePath: url.path)
            self.m_tableView.reloadData()
            // 双击打开Podfile
            //            NSWorkspace.shared.open(url)
            
            return true
        }
        return false
    }
}

// MARK: - NSMenuDelegate
extension PodfileListVC: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        // 在这里动态添加 menu item
        menu.addItem(NSMenuItem(title: "删除引用", action: #selector(handleDeleteClickedRow), keyEquivalent: ""))
    }
    @objc func handleDeleteClickedRow(){
        let idx = m_tableView.selectedRow
        guard idx >= 0,
              m_tableView.clickedColumn >= 0,
              let row: NSTableRowView = m_tableView.rowView(atRow: idx, makeIfNecessary: false),
              let cellView = row.view(atColumn: m_tableView.clickedColumn) as? NSTableCellView  else {
                  return
              }
        let cellId = cellView.identifier?.rawValue
        //        if cellId == CellIdentifiers.url {
        //            Util.pasteStr(repos[idx].URL)
        //            return
        //        }
        //        if cellId == CellIdentifiers.path {
        //            Util.pasteStr(repos[idx].path)
        //            return
        //        }
        if cellId == CellIdentifiers.name {
            //                刷新
            m_filePaths.remove(at: idx)
            m_tableView.reloadData()
            //                偏好同步
            UserDefaults.standard.set(m_filePaths, forKey: self.saveKey)
            
            return
        }
        //        if cellId == CellIdentifiers.type {
        //            Util.pasteStr(repos[idx].type)
        //            return
        //        }
    }
}

