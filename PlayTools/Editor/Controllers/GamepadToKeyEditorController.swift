//
//  GamepadToKeyEditorController.swift
//  PlayTools
//

class GamepadToKeyEditorController {

    static let shared = GamepadToKeyEditorController()
    let lock = NSLock()
    var editorWindow: UIWindow?
    weak var previousWindow: UIWindow?
    var view: GamepadToKeyEditorView! {editorWindow?.rootViewController?.view as? GamepadToKeyEditorView}

    private func initWindow() -> UIWindow {
        let window = UIWindow(windowScene: screen.windowScene!)
        window.rootViewController = GamepadToKeyEditorViewController(nibName: nil, bundle: nil)
        return window
    }

    public func switchMode() {
        lock.lock()
        if editorMode {
            saveButtons()
            editorWindow?.isHidden = true
            editorWindow?.windowScene = nil
            editorWindow?.rootViewController = nil
            // menu still holds this object until next responder hit test
            editorWindow = nil
            previousWindow?.makeKeyAndVisible()
        } else {
            previousWindow = screen.keyWindow
            editorWindow = initWindow()
            editorWindow?.makeKeyAndVisible()
            showButtons()
        }
        lock.unlock()
    }

    var editorMode: Bool { !(editorWindow?.isHidden ?? true)}

    public func setGamepadKey(_ name: String) {
        if editorMode {
            view.focus(name)
        }
    }

    public func setTargetKey(_ name: String) {
        if editorMode {
            view.setKey(name)
        }
    }

    func showButtons() {
        view.setData(keymap.currentKeymap.gamepadToKeyModel)
    }

    func saveButtons() {
        var keymapData = keymap.currentKeymap
        keymapData.gamepadToKeyModel = view.getData()
        keymap.currentKeymap = keymapData
    }
}
