import Cocoa
import QuickLookUI

final class PreviewViewController: NSViewController, QLPreviewingController {
    private var loadToken = 0

    private var previewView: CodePreviewView {
        guard let previewView = view as? CodePreviewView else {
            fatalError("Expected CodePreviewView")
        }
        return previewView
    }

    override func loadView() {
        view = CodePreviewView(
            frame: NSRect(x: 0, y: 0, width: 920, height: 640)
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: 920, height: 640)
    }

    func preparePreviewOfFile(
        at url: URL,
        completionHandler handler: @escaping (Error?) -> Void
    ) {
        _ = view
        loadToken += 1
        let token = loadToken
        previewView.showLoading(for: url)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = DocumentLoader.load(url: url)

            DispatchQueue.main.async {
                guard let self, self.loadToken == token else { return }
                self.previewView.display(result)
                handler(nil)
            }
        }
    }
}
