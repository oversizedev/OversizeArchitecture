//
// Copyright © 2026 Alexander Romanov
// OversizeDebugCommand.swift, created on 22.11.2026
//

import Foundation
import OversizeArchitecture
import OversizeArchitectureDebug
import OversizeArchitectureDebugClient

@main
enum OversizeDebugCommand {
    static func main() async {
        #if os(macOS)
        let commandLine: DebugCommandLine
        do {
            commandLine = try DebugCommandLine.parse(
                Array(CommandLine.arguments.dropFirst()),
                environment: ProcessInfo.processInfo.environment
            )
        } catch {
            writeError("\(error)\n\n\(DebugCommandLine.usage)")
            exit(64)
        }

        let client = DebugClient(configuration: DebugClient.Configuration(
            host: commandLine.host,
            port: commandLine.port,
            token: commandLine.token
        ))

        switch commandLine.command {
        case .help:
            print(DebugCommandLine.usage)
        case .mcp:
            await runMCP(client: client)
        default:
            await runRequest(commandLine, client: client)
        }
        await client.close()
        #else
        print("oversize-debug runs on macOS only")
        #endif
    }

    #if os(macOS)
    private static func runRequest(_ commandLine: DebugCommandLine, client: DebugClient) async {
        guard let request = commandLine.request else { return }
        do {
            let result = try await client.request(request.method.rawValue, params: request.params)
            print(String(decoding: try result.encodedData(prettyPrinted: true), as: UTF8.self))
        } catch let error as DebugRPCError {
            writeError("Error \(error.code): \(error.message)")
            exit(1)
        } catch {
            writeError("\(error)")
            exit(1)
        }
    }

    private static func runMCP(client: DebugClient) async {
        let handler = DebugMCPHandler(transport: client)
        writeError("oversize-debug MCP server ready, app at \(client.configuration.host):\(client.configuration.port)")
        do {
            for try await line in FileHandle.standardInput.bytes.lines {
                guard let response = await handler.handle(Data(line.utf8)) else { continue }
                var output = response
                output.append(0x0A)
                FileHandle.standardOutput.write(output)
            }
        } catch {
            writeError("stdin closed: \(error)")
        }
    }

    private static func writeError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
    #endif
}
