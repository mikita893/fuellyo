import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Ustawiane po pierwszym obiegu pętli zdarzeń, żeby nadpisać tytuł/rozmiar z nib.
    DispatchQueue.main.async {
      self.title = "FuellYo!"
      self.setContentSize(NSSize(width: 480, height: 760))
      self.center()
    }
  }
}
