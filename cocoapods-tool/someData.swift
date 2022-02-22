//
//  someData.swift
//  cocoapods-tool
//
//  Created by dfpo on 27/01/2022.
//

import Foundation
struct PodRepo {
    var name = ""
    var type = ""
    var URL = ""
    var path = ""
}
struct ShellResult {

    /// 输出的字符串
    let output: String
    /// 命令执行状态
    let status: Int32

}
