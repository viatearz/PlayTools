//
//  GamepadToKey.swift
//  PlayTools
//  
//  Created by viatearz on 2025/2/10.
//

// swiftlint:disable file_length

import GameController

class GamepadToKeyController {
    static let shared = GamepadToKeyController()
    let lock = NSLock()
    var settingWindow: UIWindow?
    weak var previousWindow: UIWindow?

    func showSettingView() {
        if settingWindow != nil {
            return
        }
        createWindow()
        let settingVc = GamepadToKeySettingViewController()
        settingVc.modalPresentationStyle = .formSheet
        settingVc.isModalInPresentation = true
        settingVc.onDismiss = {
            self.destroyWindow()
        }
        settingWindow?.rootViewController?.present(settingVc, animated: false)
    }

    private func createWindow() {
        lock.lock()
        previousWindow = screen.keyWindow
        settingWindow = UIWindow(windowScene: screen.windowScene!)
        settingWindow?.rootViewController = RootViewController()
        settingWindow?.makeKeyAndVisible()
        lock.unlock()
    }

    private func destroyWindow() {
        lock.lock()
        settingWindow?.isHidden = true
        settingWindow?.windowScene = nil
        settingWindow?.rootViewController = nil
        settingWindow = nil
        previousWindow?.makeKeyAndVisible()
        lock.unlock()
    }

    class RootViewController: UIViewController {
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
    }
}

// Keymap/KeyCodeNames.swift
extension KeyCodeNames {
    public static let keyNameToVirtualCode: [String: UInt16] =
        Dictionary(uniqueKeysWithValues: KeyCodeNames.virtualCodes.map { ($1, $0) })
}

// Controls/Backend/KeyboardAndMouse.swift
class KeyboardAndMouse {
    private static let combineKeyFlags: [UIKeyModifierFlags] = [.control, .alternate, .shift, .command]
    private static let combineKeyCodes: [UInt16] = [59, 58, 56, 55]

    static func postEvent(keyName: String, modifiers: Int, keyDown: Bool) {
        if keyName == KeyCodeNames.leftMouseButton {
            AKInterface.shared?.postMouseEvent(left: true, right: false, keyDown: keyDown)
            return
        }
        if keyName == KeyCodeNames.rightMouseButton {
            AKInterface.shared?.postMouseEvent(left: false, right: true, keyDown: keyDown)
            return
        }
        if keyName == KeyCodeNames.middleMouseButton {
            AKInterface.shared?.postMouseEvent(left: false, right: false, keyDown: keyDown)
            return
        }

        guard let keyCode = KeyCodeNames.keyNameToVirtualCode[keyName] else {
            return
        }

        if modifiers == 0 {
            AKInterface.shared?.postKeyEvent(keyCode: keyCode, keyDown: keyDown)
        } else {
            let modifierFlags = UIKeyModifierFlags(rawValue: modifiers)
            for idx in 0..<combineKeyFlags.count where modifierFlags.contains(combineKeyFlags[idx]) {
                AKInterface.shared?.postKeyEvent(keyCode: combineKeyCodes[idx], keyDown: keyDown)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                AKInterface.shared?.postKeyEvent(keyCode: keyCode, keyDown: keyDown)
            }
        }
    }
}

// Controls/Backend/Action/PlayAction.swift
class GamepadButtonToKeyAction: Action {
    let keyName: String
    let targetKeyName: String
    let targetModifiers: Int

    init(keyName: String, targetKeyName: String, targetModifiers: Int) {
        self.keyName = keyName
        self.targetKeyName = targetKeyName
        self.targetModifiers = targetModifiers
        ActionDispatcher.register(key: keyName, handler: self.update)
    }

    convenience init(data: GamepadToKey) {
        self.init(
            keyName: data.keyName,
            targetKeyName: data.targetKeyName,
            targetModifiers: data.targetModifiers)
    }

    func update(pressed: Bool) {
        if pressed {
            KeyboardAndMouse.postEvent(keyName: targetKeyName, modifiers: targetModifiers, keyDown: true)
        } else {
            KeyboardAndMouse.postEvent(keyName: targetKeyName, modifiers: targetModifiers, keyDown: false)
        }
    }

    func invalidate() {
        KeyboardAndMouse.postEvent(keyName: targetKeyName, modifiers: targetModifiers, keyDown: false)
    }
}

// Controls/Backend/Action/PlayAction.swift
class GamepadThumbstickToKeyAction: Action {
    class GamepadThumbstickButton {
        var keyName: String
        var modifiers: Int
        var pressState: Bool

        init(keyName: String, modifiers: Int, pressState: Bool) {
            self.keyName = keyName
            self.modifiers = modifiers
            self.pressState = pressState
        }
    }

    // swiftlint:disable identifier_name
    enum Direction: String, CaseIterable {
        case left = "Left"
        case right = "Right"
        case up = "Up"
        case down = "Down"
    }
    // swiftlint:enable identifier_name

    let deadZone = 0.25
    let keyName: String
    var buttons: [Direction: GamepadThumbstickButton] = [:]
    var buttonNameToDirection: [String: Direction] = [:]

    init(keyName: String) {
        self.keyName = keyName
        for direction in Direction.allCases {
            let buttonName = keyName + " " + direction.rawValue
            self.buttonNameToDirection[buttonName] = direction
        }
        ActionDispatcher.register(key: keyName, handler: self.thumbstickUpdate)
    }

    func addButton(data: GamepadToKey) {
        guard let direction = buttonNameToDirection[data.keyName] else {
            return
        }
        buttons[direction] = GamepadThumbstickButton(
            keyName: data.targetKeyName,
            modifiers: data.targetModifiers,
            pressState: false
        )
    }

    func thumbstickUpdate(_ deltaX: CGFloat, _ deltaY: CGFloat) {
        buttonUpdate(direction: .left, pressed: deltaX < -deadZone)
        buttonUpdate(direction: .right, pressed: deltaX > deadZone)
        buttonUpdate(direction: .up, pressed: deltaY > deadZone)
        buttonUpdate(direction: .down, pressed: deltaY < -deadZone)
    }

    func buttonUpdate(direction: Direction, pressed: Bool) {
        guard let button = buttons[direction] else {
            return
        }
        if pressed {
            if !button.pressState {
                button.pressState = true
                KeyboardAndMouse.postEvent(keyName: button.keyName, modifiers: button.modifiers, keyDown: true)
            }
        } else {
            if button.pressState {
                button.pressState = false
                KeyboardAndMouse.postEvent(keyName: button.keyName, modifiers: button.modifiers, keyDown: false)
            }
        }
    }

    func invalidate() {
        for (_, button) in buttons {
            KeyboardAndMouse.postEvent(keyName: button.keyName, modifiers: button.modifiers, keyDown: false)
            button.pressState = false
        }
    }
}

// Controls/Frontend/EventAdapter/Controller/Instances/GamepadToKeyControllerEventAdapter.swift
public class GamepadToKeyControllerEventAdapter: ControllerEventAdapter {
    public func handleValueChanged(_ profile: GCExtendedGamepad, _ element: GCControllerElement) {
        var alias: String?
        if let dpad = element as? GCControllerDirectionPad {
            alias = getDirectionPadAlias(dpad)
        } else {
            alias = element.aliases.first
        }
        if let alias = alias {
            GamepadToKeySettingViewController.current?.setGamepadKey(keyName: alias)
        }
    }

    func getDirectionPadAlias(_ dpad: GCControllerDirectionPad) -> String? {
        let deltaX = dpad.xAxis.value
        let deltaY = dpad.yAxis.value
        if abs(deltaX) > 0 || abs(deltaY) > 0 {
            if abs(deltaX) > abs(deltaY) {
                return deltaX < 0 ? dpad.left.aliases.first : dpad.right.aliases.first
            } else {
                return deltaY > 0 ? dpad.up.aliases.first : dpad.down.aliases.first
            }
        }
        return nil
    }
}

// Controls/Frontend/EventAdapter/Mouse/Instances/GamepadToKeyMouseEventAdapter.swift
public class GamepadToKeyMouseEventAdapter: MouseEventAdapter {
    public func handleScrollWheel(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
        false
    }

    public func handleMove(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
        false
    }

    public func handleLeftButton(pressed: Bool) -> Bool {
        false
    }

    public func handleOtherButton(id: Int, pressed: Bool) -> Bool {
        if pressed {
            GamepadToKeySettingViewController.current?.setMouseButton(
                keyName: EditorMouseEventAdapter.getMouseButtonName(id))
        }
        return true
    }

    public func cursorHidden() -> Bool {
        false
    }
}

// Editor/Models/Elements/Elements.swift
struct GamepadToKey: Codable {
    var keyName: String
    var targetKeyName: String
    var targetModifiers: Int

    var thumbstickName: String? {
        if let range = keyName.range(of: "Thumbstick") {
            return String(keyName[..<range.upperBound])
        }
        return nil
    }
}

// Editor/Views/GamepadToKeySettingViewController.swift
class GamepadToKeySettingViewController: UIViewController {
    static weak var current: GamepadToKeySettingViewController?
    let toolbar = UIToolbar()
    let tableView = UITableView()
    var keymapData = ExtraKeymappingData(bundleIdentifier: "")
    var indexOfEditingGamepadInput: IndexPath?
    var indexOfEditingKeyboardOutput: IndexPath?
    var onDismiss: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        GamepadToKeySettingViewController.current = self
        loadData()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        ModeAutomaton.onOpenGamepadToKeySetting()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        ActionDispatcher.build()
        ModeAutomaton.onCloseGamepadToKeySetting()
        GamepadToKeySettingViewController.current = nil
    }

    deinit {
        GamepadToKeySettingViewController.current = nil
    }

    // listen for keyboard events manually
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)

        for press in presses {
            guard let key = press.key else { continue }
            guard let modifierFlags = event?.modifierFlags else { continue }
            setKeyboardKey(keyCode: key.keyCode, modifierFlags: modifierFlags)
        }
    }

    private func setupView() {
        view.backgroundColor = .white
        setupToolbar()
        setupTableView()
    }

    func loadData() {
        self.keymapData = ExtraKeymapping.shared.keymapData
    }

    func saveData() {
        ExtraKeymapping.shared.keymapData = self.keymapData
    }

    func setGamepadKey(keyName: String) {
        if let indexPath = self.indexOfEditingGamepadInput {
            keymapData.gamepadToKeyModels[indexPath.row].keyName = keyName
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    func setKeyboardKey(keyCode: UIKeyboardHIDUsage, modifierFlags: UIKeyModifierFlags) {
        guard let indexPath = self.indexOfEditingKeyboardOutput else {
            return
        }
        guard let keyName = KeyCodeNames.keyCodes[keyCode.rawValue] else {
            return
        }

        keymapData.gamepadToKeyModels[indexPath.row].targetKeyName = keyName
        keymapData.gamepadToKeyModels[indexPath.row].targetModifiers = keyCode.isModifier ? 0 : modifierFlags.rawValue
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }

    func setMouseButton(keyName: String) {
        guard let indexPath = self.indexOfEditingKeyboardOutput else {
            return
        }
        keymapData.gamepadToKeyModels[indexPath.row].targetKeyName = keyName
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
}

extension UIKeyboardHIDUsage {
    var isModifier: Bool {
        return self == .keyboardLeftControl || self == .keyboardRightControl ||
            self == .keyboardLeftAlt || self == .keyboardRightAlt ||
            self == .keyboardLeftShift || self == .keyboardRightShift ||
            self == .keyboardLeftGUI || self == .keyboardRightGUI
    }
}

// Editor/Views/GamepadToKeySettingViewController+Toolbar.swift
extension GamepadToKeySettingViewController {

    func setupToolbar() {
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        // Create toolbar items
        // Close
        let closeButton = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(closeDialog))
        // Add
        let addButton = UIBarButtonItem(title: "添加", style: .plain, target: self, action: #selector(addNewRow))

        // Create a flexible space to center the title
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        // Create a custom title label to be added to the toolbar
        let titleLabel = UILabel()
        titleLabel.text = "手柄映射键盘设置" // Gamepad to Key Setting
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center

        // Wrap the titleLabel in a UIBarButtonItem
        let titleItem = UIBarButtonItem(customView: titleLabel)

        // Set the toolbar items (close button, flexible space, title, flexible space, and add button)
        toolbar.items = [closeButton, flexibleSpace, titleItem, flexibleSpace, addButton]

        self.navigationController?.view.addSubview(toolbar)

        // Add the toolbar to the view
        view.addSubview(toolbar)

        // Set up toolbar constraints (pinned to top of the view)
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44)  // Standard toolbar height
        ])
    }

    @objc func closeDialog() {
        saveData()
        dismiss(animated: false) {
            self.onDismiss?()
        }
    }

    @objc func addNewRow() {
        indexOfEditingGamepadInput = nil
        indexOfEditingKeyboardOutput = nil
        keymapData.gamepadToKeyModels.append(GamepadToKey(keyName: "", targetKeyName: "LMB", targetModifiers: 0))
        tableView.reloadData()
    }
}

// Editor/Views/GamepadToKeySettingViewController+TableView.swift
extension GamepadToKeySettingViewController: UITableViewDelegate,
                                             UITableViewDataSource,
                                             GamepadToKeySettingCellDelegate {

    func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self

        // Register the custom cell
        tableView.register(GamepadToKeySettingCell.self, forCellReuseIdentifier: GamepadToKeySettingCell.indentifier)

        // Add the table view to the view
        view.addSubview(tableView)

        // Set up table view constraints (below the toolbar)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keymapData.gamepadToKeyModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: GamepadToKeySettingCell.indentifier, for: indexPath) as? GamepadToKeySettingCell else {
            return UITableViewCell()
        }

        let data = keymapData.gamepadToKeyModels[indexPath.row]
        cell.setupCell(data)
        cell.highlightGamepadInput(indexPath == indexOfEditingGamepadInput)
        cell.highlightKeyboardOutput(indexPath == indexOfEditingKeyboardOutput)
        cell.delegate = self
        return cell
    }

    func didTapGamepadInputLabel(in cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            indexOfEditingGamepadInput = indexPath
            indexOfEditingKeyboardOutput = nil
            tableView.reloadData()
        }
    }

    func didTapKeyboardOutputLabel(in cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            indexOfEditingGamepadInput = nil
            indexOfEditingKeyboardOutput = indexPath
            tableView.reloadData()
        }
    }

    func didTapDeleteButton(in cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            indexOfEditingGamepadInput = nil
            indexOfEditingKeyboardOutput = nil
            keymapData.gamepadToKeyModels.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
}

// Editor/Views/GamepadToKeySettingCell.swift
class GamepadToKeySettingCell: UITableViewCell {
    weak var delegate: GamepadToKeySettingCellDelegate?
    let gamepadInputLabel = UILabel()
    let keyboardOutputLabel = UILabel()
    let arrowImageView = UIImageView()
    let deleteButton = UIButton(type: .system)

    class var indentifier: String {
        String(describing: self)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.selectionStyle = .none

        // First text label setup
        gamepadInputLabel.backgroundColor = UIColor.systemGray6
        gamepadInputLabel.textColor = .black
        gamepadInputLabel.textAlignment = .center
        gamepadInputLabel.layer.cornerRadius = 5
        gamepadInputLabel.layer.masksToBounds = true
        gamepadInputLabel.layer.borderWidth = 1
        gamepadInputLabel.layer.borderColor = UIColor.gray.cgColor
        gamepadInputLabel.isUserInteractionEnabled = true

        // Add tap gesture to the first text label
        let firstTapGesture = UITapGestureRecognizer(target: self, action: #selector(gamepadInputLabelTapped))
        gamepadInputLabel.addGestureRecognizer(firstTapGesture)

        // Second text label setup
        keyboardOutputLabel.backgroundColor = UIColor.systemGray6
        keyboardOutputLabel.textColor = .black
        keyboardOutputLabel.textAlignment = .center
        keyboardOutputLabel.layer.cornerRadius = 5
        keyboardOutputLabel.layer.masksToBounds = true
        keyboardOutputLabel.layer.borderWidth = 1
        keyboardOutputLabel.layer.borderColor = UIColor.gray.cgColor
        keyboardOutputLabel.isUserInteractionEnabled = true

        // Add tap gesture to the second text label
        let secondTapGesture = UITapGestureRecognizer(target: self, action: #selector(keyboardOutputLabelTapped))
        keyboardOutputLabel.addGestureRecognizer(secondTapGesture)

        // Arrow image setup (using a right arrow system image)
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.contentMode = .scaleAspectFit

        // Delete button setup
        deleteButton.setTitle("删除"/* Delete */, for: .normal)
        deleteButton.setTitleColor(.red, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)

        // Add the UI elements to the content view
        contentView.addSubview(gamepadInputLabel)
        contentView.addSubview(arrowImageView)
        contentView.addSubview(keyboardOutputLabel)
        contentView.addSubview(deleteButton)

        // Set up constraints
        setupConstraints()
    }

    private func setupConstraints() {
        gamepadInputLabel.translatesAutoresizingMaskIntoConstraints = false
        keyboardOutputLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // First text label constraints
            gamepadInputLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            gamepadInputLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            gamepadInputLabel.widthAnchor.constraint(equalToConstant: 200),
            gamepadInputLabel.heightAnchor.constraint(equalToConstant: 30),

            // Arrow image constraints
            arrowImageView.leadingAnchor.constraint(equalTo: gamepadInputLabel.trailingAnchor, constant: 8),
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 20),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20),

            // Second text label constraints
            keyboardOutputLabel.leadingAnchor.constraint(equalTo: arrowImageView.trailingAnchor, constant: 8),
            keyboardOutputLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            keyboardOutputLabel.widthAnchor.constraint(equalToConstant: 200),
            keyboardOutputLabel.heightAnchor.constraint(equalToConstant: 30),

            // Delete button constraints
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    @objc private func gamepadInputLabelTapped() {
        delegate?.didTapGamepadInputLabel(in: self)
    }

    @objc private func keyboardOutputLabelTapped() {
        delegate?.didTapKeyboardOutputLabel(in: self)
    }

    @objc private func deleteButtonTapped() {
        delegate?.didTapDeleteButton(in: self)
    }

    func setupCell(_ data: GamepadToKey) {
        gamepadInputLabel.text = data.keyName

        let modifiersName = getModifiersDisplayName(data.targetModifiers)
        let keyCodeName = data.targetKeyName
        keyboardOutputLabel.text = !modifiersName.isEmpty ? "\(modifiersName) \(keyCodeName)" : keyCodeName
    }

    func highlightGamepadInput(_ highlight: Bool) {
        setLabelHighlight(label: gamepadInputLabel, highlight: highlight)
    }

    func highlightKeyboardOutput(_ highlight: Bool) {
        setLabelHighlight(label: keyboardOutputLabel, highlight: highlight)
    }

    private func setLabelHighlight(label: UILabel, highlight: Bool) {
        if highlight {
            label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        } else {
            label.backgroundColor = UIColor.systemGray6
        }
    }

    private func getModifiersDisplayName(_ modifiers: Int) -> String {
        let modifierFlags = UIKeyModifierFlags(rawValue: modifiers)
        var str = ""
        if modifierFlags.contains(.control) {
            str += "⌃"
        }
        if modifierFlags.contains(.alternate) {
            str += "⌥"
        }
        if modifierFlags.contains(.shift) {
            str += "⇧"
        }
        if modifierFlags.contains(.command) {
            str += "⌘"
        }
        return str
    }
}

protocol GamepadToKeySettingCellDelegate: AnyObject {
    func didTapGamepadInputLabel(in cell: UITableViewCell)
    func didTapKeyboardOutputLabel(in cell: UITableViewCell)
    func didTapDeleteButton(in cell: UITableViewCell)
}
