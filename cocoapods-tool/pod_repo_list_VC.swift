//
//  ViewController.swift
//  cocoapods-tool
//
//  Created by dfpo on 24/01/2022.
//

import Cocoa
enum CellIdentifiers {
    static let name = "name"
    static let type = "type"
    static let url = "url"
    static let path = "path"
    static let action = "action"
}

final class pod_repo_list_VC: NSViewController {
    /// 输出显示
    @IBOutlet var outputText:NSTextView!
    
    @IBOutlet var spinner:NSProgressIndicator!
    @IBOutlet weak var m_tableView: NSTableView!
    
    @IBOutlet weak var buildButton: NSButton!
    private var isRunning = false
    
    private var outputPipe:Pipe!
    private  var buildTask:Process!
    
    
    private var repos = [PodRepo]()
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        m_tableView.doubleAction = #selector(doubleClickOnResultRow)
        m_tableView.rowHeight = 46
        cellAddRightMenu()
        loadRepos()
    }
    private func loadRepos() {
        guard Util.hasPodFolder else {
            outputText.string = "未发现~/.cocoapods文件夹"
            return
        }
        
        repos.removeAll()
        m_tableView.reloadData()
        if Util.m_podFilePath.count > 0 {
            outputText.string = "已获取到pod命令位置\(Util.m_podFilePath)"
            runTask()
            let strs = Util.run_pod_repo_list(outputText: outputText).output.split(separator: "\n")
            stopedTask()
            // 四个一个数组
            let step = 4
            let finalArray = stride(from: 0, to: strs.endIndex - (strs.endIndex % step), by: step).map {
                Array(strs[$0...$0+(step - 1)])
            }
            for array in finalArray {
                var repo = PodRepo()
                if array.count < step {
                    continue
                }
                let repoName = String(array[0])
                if repos.map({$0.name}).contains(repoName) {
                    continue
                }
                repo.name = repoName.trimmingCharacters(in: .whitespaces)
                repo.type = String(array[1]).replacingOccurrences(of: "- Type:", with: "").trimmingCharacters(in: .whitespaces)
                repo.URL = String(array[2]).replacingOccurrences(of: "- URL:", with: "").trimmingCharacters(in: .whitespaces)
                repo.path = String(array[3]).replacingOccurrences(of: "- Path:", with: "").trimmingCharacters(in: .whitespaces)
                repos.append(repo)
            }
            m_tableView.reloadData()
        } else {
            outputText.string = "未获取到pod命令位置"
        }
    }
    // cell上右键菜单 https://www.codercto.com/a/9125.html
    private func cellAddRightMenu() {
        let menu = NSMenu()
        menu.delegate = self
        m_tableView.menu = menu
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
        let cellId = cellView.identifier?.rawValue
        
        if cellId == CellIdentifiers.url {
            let url = repos[idx].URL
            Util.openUrl(url)
            outputText.string = "尝试打开url：\(url)"
            return
        }
        
        if cellId == CellIdentifiers.path {
            let path = repos[idx].path
            Util.openPath(path)
            outputText.string = "尝试打开路径：\(path)"
            
            return
        }
        if cellId == CellIdentifiers.name {
            let name = repos[idx].name
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(name, forType: .string)
            if pb.string(forType: .string) == name {
                outputText.string = "复制成功：\(name)"
            }
            return
        }
        if cellId == CellIdentifiers.type {
            print(repos[idx].type)
            return
        }
    }
    
    
    private func runTask() {
        if isRunning {
            // 有任务在运行
            let alert = NSAlert()
            alert.messageText = "有任务在运行"
            alert.addButton(withTitle: "好的")
            alert.informativeText = buildButton.title
            alert.runModal()
            return
        }
        isRunning = true
        buildButton.isEnabled = !isRunning
        spinner.startAnimation(self)
        outputText.string = ""
    }
    private func stopedTask() {
        buildButton.isEnabled = true
        
        spinner.stopAnimation(self)
        isRunning = false
        buildButton.isEnabled = true
    }
    
    @objc func clickUpdateBtn(_ btn: NSButton) {
        if isRunning {
            
            // 有任务在运行
            let alert = NSAlert()
            alert.messageText = "有任务在运行"
            alert.addButton(withTitle: "好的")
            alert.runModal()
            return
        }
        let repoName = repos[btn.tag].name
        runTask()
        Util.run_pod_repo_update(podRepoName: repoName, outputText: outputText)
        stopedTask()
    }
    
    @IBAction func clickRefreshBtn(_ sender: NSButton) {
        loadRepos()
    }
    @IBAction func stopTask(_ sender:AnyObject) {
        
        if isRunning {
            buildTask.terminate()
        }
    }
}
// MARK: - NSTableViewDataSource
extension pod_repo_list_VC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        print(repos.count)
        return repos.count
    }
}
// MARK: - NSTableViewDelegate
extension pod_repo_list_VC: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var cellIdentifier: String = ""
        let item = repos[row]
        var text: String = ""
        
        if tableColumn == tableView.tableColumns[0] {
            text = item.name
            cellIdentifier = CellIdentifiers.name
        } else if tableColumn == tableView.tableColumns[1] {
            text = item.type
            cellIdentifier = CellIdentifiers.type
        } else if tableColumn == tableView.tableColumns[2] {
            text = item.URL
            cellIdentifier = CellIdentifiers.url
        } else if tableColumn == tableView.tableColumns[3] {
            text = item.path
            cellIdentifier = CellIdentifiers.path
        } else if tableColumn == tableView.tableColumns[4] {
            
            cellIdentifier = CellIdentifiers.action
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier), owner: self) as? NSTableCellView {
            cell.textField?.stringValue = text
            if tableColumn == tableView.tableColumns[4] {
                if let btn = cell.subviews.filter({$0 is NSButton}).first as? NSButton {
                    btn.tag = row
                    // 注意不设置target可能有时候，只有在选中这一行cell时，点按钮才会有响应
                    btn.target = self
                    btn.action = #selector(clickUpdateBtn)
                    
                }}
            return cell
        }
        return nil
    }
}


// MARK: - NSMenuDelegate
extension pod_repo_list_VC: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        // 在这里动态添加 menu item
        menu.addItem(NSMenuItem(title: "复制", action: #selector(handleCopyClickedRow), keyEquivalent: ""))
    }
    @objc func handleCopyClickedRow(){
        let idx = m_tableView.selectedRow
        guard idx >= 0,
              m_tableView.clickedColumn >= 0,
              let row: NSTableRowView = m_tableView.rowView(atRow: idx, makeIfNecessary: false),
              let cellView = row.view(atColumn: m_tableView.clickedColumn) as? NSTableCellView  else {
                  return
              }
        let cellId = cellView.identifier?.rawValue
        if cellId == CellIdentifiers.url {
            Util.pasteStr(repos[idx].URL)
            return
        }
        if cellId == CellIdentifiers.path {
            Util.pasteStr(repos[idx].path)
            return
        }
        if cellId == CellIdentifiers.name {
            Util.pasteStr(repos[idx].name)
            return
        }
        if cellId == CellIdentifiers.type {
            Util.pasteStr(repos[idx].type)
            return
        }
    }
}

