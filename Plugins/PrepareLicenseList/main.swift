//
//  main.swift
//
//
//  Created by ky0me22 on 2022/09/29.
//

import Foundation
import PackagePlugin

@main
struct PrepareLicenseList: BuildToolPlugin {
    struct SourcePackagesNotFoundError: Error & CustomStringConvertible {
        let description: String = "SourcePackages not found"
    }

    func sourcePackages(_ pluginWorkDirectory: Path) throws -> Path {
        var tmpPath = pluginWorkDirectory
        guard pluginWorkDirectory.string.contains("SourcePackages") else {
            throw SourcePackagesNotFoundError()
        }
        while tmpPath.lastComponent != "SourcePackages" {
            tmpPath = tmpPath.removingLastComponent()
        }
        return tmpPath
    }

    // This command does not work as expected in Xcode 14.2.
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        if let isInPreview = ProcessInfo().environment["ENABLE_PREVIEWS"] as? String {
            if isInPreview.uppercased() == "YES" {
                return []
            }
        }
        let executablePath = try context.tool(named: "spp").path
        let sourcePackagesPath = try sourcePackages(context.pluginWorkDirectory)
        let outputPath = context.pluginWorkDirectory.appending(["Resources"])

        return [
            .buildCommand(
                displayName: "Prepare LicenseList",
                executable: executablePath,
                arguments: [
                    outputPath.string,
                    sourcePackagesPath.string
                ],
                outputFiles: [
                    outputPath.appending(["license-list.plist"])
                ]
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)

import XcodeProjectPlugin

// This command works as expected.
extension PrepareLicenseList: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodeProjectPlugin.XcodePluginContext,
        target: XcodeProjectPlugin.XcodeTarget
    ) throws -> [PackagePlugin.Command] {
        if let isInPreview = ProcessInfo().environment["ENABLE_PREVIEWS"] as? String {
            if isInPreview.uppercased() == "YES" {
                return []
            }
        }
        let executablePath = try context.tool(named: "spp").path
        let sourcePackagesPath = try sourcePackages(context.pluginWorkDirectory)
        let outputPath = context.pluginWorkDirectory.appending(["Resources"])

        return [
            .buildCommand(
                displayName: "Prepare LicenseList",
                executable: executablePath,
                arguments: [
                    outputPath.string,
                    sourcePackagesPath.string
                ],
                outputFiles: [
                    outputPath.appending(["license-list.plist"])
                ]
            ),
        ]
    }
}

#endif
