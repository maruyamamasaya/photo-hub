import SwiftUI

@main
struct PhotoHubApp: App {
    @StateObject private var library = LibraryModel()
    var body: some Scene { WindowGroup { RootView().environmentObject(library) } }
}
