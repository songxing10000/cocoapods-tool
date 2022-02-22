//
//  swift
//  cocoapods-tool
//
//  Created by dfpo on 27/01/2022.
//

import Foundation
import Cocoa
class Util {
    /*
     用gem装的在 /usr/local/bin/pod
     用brew装的在 /usr/local/Cellar/cocoapods/1.11.2_1/bin/pod (注意1.11.2_1这个是pod版本变化的)
     */
    static var m_podFilePath: String = {
         return Util.run_which_pod(outputText:nil).output.replacingOccurrences(of: "\n", with: "")
    }()
    /// 可代码获取，也可终端运行 echo $PATH 获取
    static var m_systemPath: String = {
        // https://stackoverflow.com/questions/41535451/how-to-access-the-terminals-path-variable-from-within-my-mac-app-it-seems-to
        let taskShell = Process()
        taskShell.launchPath = "/usr/bin/env"
        taskShell.arguments = ["/bin/bash","-c","eval $(/usr/libexec/path_helper -s) ; echo $PATH"]
        let pipeShell = Pipe()
        taskShell.standardOutput = pipeShell
        taskShell.standardError = pipeShell
        taskShell.launch()
        taskShell.waitUntilExit()
        let dataShell = pipeShell.fileHandleForReading.readDataToEndOfFile()
        var outputShell: String? = String(data: dataShell, encoding:  .utf8)
        outputShell = outputShell?.replacingOccurrences(of: "\n", with: "", options: .literal, range: nil)
        return outputShell!
    }()
    /// 在 Finder 中打开路径
   class func openPath(_ filePath: String?) {
        print("尝试在Finder中打开: \(String(describing:filePath))")
        guard let filePath = filePath else {
            return
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: filePath))
    }
    /// 浏览器打开url
    class func openUrl(_ urlStr: String?) {
        print("尝试打开url: \(String(describing:urlStr))")
        guard let urlStr = urlStr, let url = URL(string: urlStr) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
    
    /// 复制字符串到粘贴板
    class func pasteStr(_ str: String?) {
        guard let str = str else {
            return
        }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(str, forType: .string)
        if pb.string(forType: .string) == str {
            print("复制成功：\(str)")
        }
    }
    /// 有没有 ~/.cocoapods 文件夹
    static var hasPodFolder: Bool = {
        return FileManager.default.fileExists(atPath: NSHomeDirectory().appending("/.cocoapods"))
    }()
    
    /// 执行 which pod
    /// - Parameters:
    ///     - PATH: 终端运行 echo $PATH 获取
    @discardableResult
    class func run_which_pod(outputText:NSTextView?) -> ShellResult {
        var environment = [String:String]()
        environment["LANG"] = "en_US.UTF-8"
        environment["PATH"] = m_systemPath
        return shell(launchPath: "/usr/bin/which", environment: environment, arguments:"pod", outputText: outputText)
    }
    /// 获取pod仓库列表（ pod repo list）
    /// - Parameters:
    ///   - PATH: 终端运行 echo $PATH 获取
    ///   - podPath: pod二进制的路径
    @discardableResult
    class func run_pod_repo_list(outputText:NSTextView?) -> ShellResult {
        var environment = [String:String]()
        environment["LANG"] = "en_US.UTF-8"
        environment["PATH"] = m_systemPath
        environment["CP_HOME_DIR"] = NSHomeDirectory().appending("/.cocoapods")
        return shell(launchPath:m_podFilePath, environment: environment, arguments:"repo", "list", outputText: outputText)
    }
    
    
    /// 更新某个仓库（pod repo update repoName）
    /// - Parameters:
    ///   - PATH: 终端运行 echo $PATH 获取
    ///   - podPath: pod二进制的路径
    ///   - podRepoName: 仓库名
    @discardableResult
    class func run_pod_repo_update(podRepoName: String, outputText:NSTextView?) -> ShellResult {
        var environment = [String:String]()
        environment["LANG"] = "en_US.UTF-8"
        environment["PATH"] = m_systemPath
        environment["CP_HOME_DIR"] = NSHomeDirectory().appending("/.cocoapods")
        return shell(launchPath:m_podFilePath, environment: environment, arguments:"repo", "update", podRepoName, outputText: outputText)
    }
    
    
    
    /// 执行 shell命令 https://github.com/toddkramer/tutorials/blob/master/CodeCoverage/generate-coverage.swift
    /// - Parameters:
    ///   - launchPath: 二进制路径
    ///   - environment: 环境
    ///   - arguments: 参数
    /// - Returns: 输出状态及数据
    @discardableResult
    class func shell(launchPath:String, environment: [String : String]?, arguments: String..., outputText:NSTextView?) -> ShellResult {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        task.environment = environment
        

        let pipe = Pipe()
        task.standardOutput = pipe
        let outputHandler = pipe.fileHandleForReading
        outputHandler.waitForDataInBackgroundAndNotify()
        
        var output = ""
        var dataObserver: NSObjectProtocol!
        let notificationCenter = NotificationCenter.default
        let dataNotificationName = NSNotification.Name.NSFileHandleDataAvailable
        dataObserver = notificationCenter.addObserver(forName: dataNotificationName, object: outputHandler, queue: nil) {  notification in
            let data = outputHandler.availableData
            guard data.count > 0 else {
                if let dataObserver = dataObserver {
                    notificationCenter.removeObserver(dataObserver)
                }
                return
            }
            if let line = String(data: data, encoding: .utf8) {
                  let previousOutput = outputText?.string ?? ""
                    let nextOutput = previousOutput + "\n" + line
                    outputText?.string = nextOutput
                    output = output + line + "\n"
                    print(line)
                    let range = NSRange(location:nextOutput.count,length:0)
                    outputText?.scrollRangeToVisible(range)
                 
                
            }
            outputHandler.waitForDataInBackgroundAndNotify()
        }
        
        task.launch()
        task.waitUntilExit()
        return ShellResult(output: output, status: task.terminationStatus)
    }
    
    /// 在某个文件处执行pod install
    /// - Parameters:
    ///   - path: Podfile路径或Podfile直接上层文件夹路径
    ///   - outputText: 输出显示控件
    class func doPodInstallAtPath(path: String?, outputText:NSTextView?) {
        guard let path = path, !path.isEmpty else {
            return
        }
        var environment = [String:String]()
        environment["LANG"] = "en_US.UTF-8"
        environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:/Users/dfpo/development/flutter/bin"
        environment["CP_HOME_DIR"] = NSHomeDirectory().appending("/.cocoapods")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh/")
        var args : [String]!
        args = []
        
        args.append("-c")
        args.append("cd \(path.replacingOccurrences(of: "/Podfile", with: "")) && \(Util.m_podFilePath) install")
        process.arguments = args
        process.environment = environment
        process.terminationHandler = { (process) in
            print("\ndidFinish: \(!process.isRunning)")
        }
        let pipe = Pipe()
        process.standardOutput = pipe
        let outputHandler = pipe.fileHandleForReading
        outputHandler.waitForDataInBackgroundAndNotify()
        
        var output = ""
        var dataObserver: NSObjectProtocol!
        let notificationCenter = NotificationCenter.default
        let dataNotificationName = NSNotification.Name.NSFileHandleDataAvailable
        dataObserver = notificationCenter.addObserver(forName: dataNotificationName, object: outputHandler, queue: nil) {  notification in
            let data = outputHandler.availableData
            guard data.count > 0 else {
                if let dataObserver = dataObserver {
                    notificationCenter.removeObserver(dataObserver)
                }
                return
            }
            if let line = String(data: data, encoding: .utf8) {
                let previousOutput = outputText?.string ?? ""
                let nextOutput = previousOutput + "\n" + line
                outputText?.string = nextOutput
                output = output + line + "\n"
                print(line)
                let range = NSRange(location:nextOutput.count,length:0)
                outputText?.scrollRangeToVisible(range)
                
                
            }
            outputHandler.waitForDataInBackgroundAndNotify()
        }
        
        
        do {
            try process.run()
        } catch {}
        
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.activate(ignoringOtherApps:true)
        app.run()
    }
}
