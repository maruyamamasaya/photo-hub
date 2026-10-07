import SwiftUI
import PhotosUI
import Photos
import PhotoHubCore

struct RootView: View {
    @EnvironmentObject var library: LibraryModel
    var body: some View {
        TabView {
            NavigationStack { PhotoGrid() }.tabItem { Label("写真", systemImage: "photo.on.rectangle") }
            NavigationStack { AlbumsView() }.tabItem { Label("アルバム", systemImage: "rectangle.stack") }
            NavigationStack { SettingsView() }.tabItem { Label("設定", systemImage: "gearshape") }
        }
        .alert("Photo Hub", isPresented: Binding(get: { library.message != nil }, set: { if !$0 { library.message = nil } })) { Button("OK") { library.message = nil } } message: { Text(library.message ?? "") }
    }
}
struct PhotoGrid: View {
    @EnvironmentObject var library: LibraryModel
    @State private var selection: [PhotosPickerItem] = []
    var album: Album?
    private var visible: [Photo] { library.photos.filter { photo in photo.state != .deleting && (album == nil || library.members.contains { $0.albumID == album?.id && $0.photoID == photo.id }) } }
    var body: some View {
        ScrollView {
            if visible.isEmpty { ContentUnavailableView("写真がありません", systemImage: "photo", description: Text("右上の＋から写真を取り込めます。")) }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                ForEach(visible) { photo in
                    NavigationLink { PhotoDetail(initialID: photo.id, photoIDs: visible.map(\.id)) } label: {
                        ZStack(alignment: .bottomTrailing) {
                            PhotoImage(photo: photo, kind: .thumbnail).aspectRatio(1, contentMode: .fit).clipped()
                            if photo.favorite { Image(systemName: "heart.fill").foregroundStyle(.white).padding(6) }
                            if photo.state != .uploaded { Image(systemName: photo.state == .failed ? "exclamationmark.icloud" : "icloud.and.arrow.up").foregroundStyle(.white).padding(6).background(.black.opacity(0.4)) }
                        }
                    }.buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(album?.name ?? "写真")
        .toolbar {
            if album == nil {
                PhotosPicker(selection: $selection, maxSelectionCount: 100, matching: .images, preferredItemEncoding: .current, photoLibrary: .shared()) { Image(systemName: "plus") }.disabled(library.busy)
            }
        }
        .onChange(of: selection) { _, items in
            let ids = items.compactMap(\.itemIdentifier)
            Task {
                if !items.isEmpty && ids.isEmpty { library.message = "選択した写真の識別子を取得できません。写真へのアクセスを確認してください。" }
                else { await library.importPhotos(ids: ids) }
                selection = []
            }
        }
        .overlay(alignment: .bottom) { if library.busy { ProgressView("処理中…").padding().background(.regularMaterial, in: Capsule()) } }
    }
}
struct PhotoImage: View {
    @EnvironmentObject var library: LibraryModel
    let photo: Photo
    let kind: ImageKind
    @State private var image: UIImage?
    @State private var loading = true
    var body: some View {
        GeometryReader { geometry in
            if let image { Image(uiImage: image).resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped() }
            else { ZStack { Color.secondary.opacity(0.12); if loading { ProgressView() } else { Image(systemName: "photo.badge.exclamationmark").foregroundStyle(.secondary) } }.frame(width: geometry.size.width, height: geometry.size.height) }
        }
        .task(id: photo.id + kind.rawValue) {
            loading = true
            if let file = await library.image(photo, kind: kind) {
                let loaded = await Task.detached { UIImage(contentsOfFile: file.path) }.value
                if !Task.isCancelled { image = loaded }
            }
            loading = false
        }
        .accessibilityLabel(photo.filename)
    }
}
struct ZoomImage: UIViewRepresentable {
    let image: UIImage
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UIScrollView {
        let scroll = ZoomScrollView(); scroll.minimumZoomScale = 1; scroll.maximumZoomScale = 5
        scroll.delegate = context.coordinator; scroll.photoView = context.coordinator.imageView; scroll.addSubview(context.coordinator.imageView)
        context.coordinator.imageView.contentMode = .scaleAspectFit
        scroll.bouncesZoom = true; return scroll
    }
    func updateUIView(_ scroll: UIScrollView, context: Context) {
        context.coordinator.imageView.image = image
        context.coordinator.imageView.frame = scroll.bounds
        scroll.contentSize = scroll.bounds.size
    }
    final class Coordinator: NSObject, UIScrollViewDelegate {
        let imageView = UIImageView()
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    }
}
final class ZoomScrollView: UIScrollView {
    weak var photoView: UIImageView?
    private var previousSize = CGSize.zero
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != previousSize { previousSize = bounds.size; zoomScale = 1; photoView?.frame = CGRect(origin: .zero, size: bounds.size); contentSize = bounds.size }
    }
}
struct DetailImage: View {
    @EnvironmentObject var library: LibraryModel
    let photo: Photo
    @State private var image: UIImage?
    @State private var failed = false
    var body: some View {
        Group {
            if let image { ZoomImage(image: image) }
            else if failed { ContentUnavailableView("画像を読み込めません", systemImage: "wifi.slash", description: Text("キャッシュがないか、通信・保存オブジェクトを確認してください。")) }
            else { ProgressView() }
        }.task(id: photo.id) {
            if let file = await library.image(photo, kind: .display) {
                image = await Task.detached { UIImage(contentsOfFile: file.path) }.value
            }
            failed = image == nil
        }
    }
}
struct PhotoDetail: View {
    @EnvironmentObject var library: LibraryModel
    @Environment(\.dismiss) private var dismiss
    let initialID: String
    let photoIDs: [String]
    @State private var current = ""
    @State private var confirmDelete = false
    var photo: Photo? { library.photos.first { $0.id == current } }
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $current) {
                ForEach(photoIDs, id: \.self) { id in if let photo = library.photos.first(where: { $0.id == id }) { DetailImage(photo: photo).tag(id) } }
            }.tabViewStyle(.page(indexDisplayMode: .never))
            if let photo {
                VStack(spacing: 5) {
                    Text(photo.capturedAt, format: .dateTime.year().month().day().hour().minute()).font(.caption)
                    Text("\(photo.filename) · \(ByteCountFormatter.string(fromByteCount: photo.bytes, countStyle: .file))").font(.caption2).foregroundStyle(.secondary)
                    if photo.state != .uploaded { Text(photo.error ?? "保存先へ未送信です").font(.caption).foregroundStyle(.orange) }
                    if let progress = library.progress[photo.id], photo.state == .uploading { ProgressView(value: progress) }
                    HStack {
                        Button { library.setFavorite(photo) } label: { Image(systemName: photo.favorite ? "heart.fill" : "heart") }
                        Spacer()
                        Menu { ForEach(library.albums) { album in Button { library.toggleMembership(photo: photo, album: album) } label: { Label(album.name, systemImage: library.members.contains { $0.photoID == photo.id && $0.albumID == album.id } ? "checkmark" : "plus") } } } label: { Image(systemName: "rectangle.stack.badge.plus") }
                        Spacer()
                        Button { Task { await library.saveOriginal(photo) } } label: { Image(systemName: "square.and.arrow.down") }
                        Spacer()
                        Button(role: .destructive) { confirmDelete = true } label: { Image(systemName: "trash") }
                    }.font(.title3).padding().disabled(library.busy)
                }
            }
        }.navigationTitle("写真").navigationBarTitleDisplayMode(.inline)
        .onAppear { if current.isEmpty { current = initialID } }
        .confirmationDialog("アプリから写真を削除しますか？原本・派生画像・整理情報を削除します。iPhoneの写真ライブラリは変更しません。", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("削除", role: .destructive) { if let photo { Task { await library.requestDelete(photo); dismiss() } } }
        }
    }
}
struct AlbumsView: View {
    @EnvironmentObject var library: LibraryModel
    @State private var name = ""
    @State private var creating = false
    var body: some View {
        List { ForEach(library.albums) { album in NavigationLink(album.name) { PhotoGrid(album: album) } } }
        .navigationTitle("アルバム")
        .toolbar { Button { creating = true } label: { Image(systemName: "plus") }.disabled(library.busy) }
        .alert("新しいアルバム", isPresented: $creating) { TextField("名前", text: $name); Button("作成") { library.addAlbum(name: name); name = "" }; Button("キャンセル", role: .cancel) {} }
    }
}
struct SettingsView: View {
    @EnvironmentObject var library: LibraryModel
    @State private var restoreConfirmation = false
    @State private var releaseConfirmation = false
    var body: some View {
        Form {
            Section("保存先") {
                Toggle("開発用ローカル保存", isOn: $library.localMode)
                Text(library.localMode ? "このiPhone内のテスト用保存です。機種変更・再インストールには使えません。" : "AWSへの保存には設定と本人ログインが必要です。").font(.caption)
                if !library.localMode {
                    TextField("HTTPS API URL", text: $library.configuration.api).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Cognito HTTPS domain", text: $library.configuration.domain).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Client ID", text: $library.configuration.clientID).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("本人のCognito sub", text: $library.configuration.owner).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("本人ログイン") { Task { await library.run { try await library.authentication.login(library.configuration); library.message = "ログインしました。" } } }
                    Button("ログアウト") { library.authentication.signOut(library.configuration) }
                }
            }
            Section("保存と再試行") {
                Text("写真 \(library.photos.count)件 · 未完了 \(library.photos.filter { $0.state != .uploaded }.count)件")
                Button("未完了のアップロードを実行") { Task { await library.uploadPending() } }
                Button("未完了の削除を再試行") { Task { await library.retryDeletes() } }
                Button("確認済みの端末内原本コピーを解放") { releaseConfirmation = true }.disabled(library.localMode)
            }
            Section("キャッシュ") {
                Text("上限512MB。古いサムネイル・閲覧画像から削除します。未送信原本は対象外です。").font(.caption)
                Button("キャッシュを削除") { do { if let cache = library.cache { let previous = cache.limit; cache.limit = 0; try cache.trim(); cache.limit = previous }; library.message = "キャッシュを削除しました。" } catch { library.message = error.localizedDescription } }
            }
            Section("バックアップ") {
                Button("JSONバックアップを保存") { Task { await library.backup() } }
                ShareLink("最後に書き出したJSONを共有", item: library.support.appendingPathComponent("backup.json"))
                Button("空のライブラリに復元") { restoreConfirmation = true }
                Text("アップロード・削除が全て完了してから保存してください。復元はバックアップ時点に戻り、以降の変更は含まれません。").font(.caption)
            }
        }.navigationTitle("設定").disabled(library.busy)
        .confirmationDialog("最新の正常なバックアップから復元します。バックアップ後の変更は含まれません。", isPresented: $restoreConfirmation, titleVisibility: .visible) { Button("復元") { Task { await library.restore() } } }
        .confirmationDialog("S3保存を再確認してアプリ内の原本コピーを解放します。iPhoneの写真ライブラリは変更しません。", isPresented: $releaseConfirmation, titleVisibility: .visible) { Button("解放") { Task { await library.releaseOriginals() } } }
    }
}
