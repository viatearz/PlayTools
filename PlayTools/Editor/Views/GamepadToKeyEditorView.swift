//
//  GamepadToKeyEditorView.swift
//  PlayTools
//

import GameController

class GamepadToKeyEditorViewController: UIViewController {
    override func loadView() {
        view = GamepadToKeyEditorView()
    }
}

class GamepadToKeyEditorView: UIView {
    let dpadButtons = [
        GCInputDirectionPad + " Up",
        GCInputDirectionPad + " Down",
        GCInputDirectionPad + " Left",
        GCInputDirectionPad + " Right"
    ]
    let abxyButtons = [
        GCInputButtonA,
        GCInputButtonB,
        GCInputButtonX,
        GCInputButtonY
    ]
    let triggerButtons = [
        GCInputLeftShoulder,
        GCInputLeftTrigger,
        GCInputRightShoulder,
        GCInputRightTrigger
    ]
    let leftThumbstickButtons = [
        GCInputLeftThumbstick + " Up",
        GCInputLeftThumbstick + " Down",
        GCInputLeftThumbstick + " Left",
        GCInputLeftThumbstick + " Right",
        GCInputLeftThumbstickButton
    ]
    let rightThumbstickButtons = [
        GCInputRightThumbstick + " Up",
        GCInputRightThumbstick + " Down",
        GCInputRightThumbstick + " Left",
        GCInputRightThumbstick + " Right",
        GCInputRightThumbstickButton
    ]
    let specialButtons = [
        GCInputButtonOptions,
        GCInputButtonMenu,
        GCInputButtonShare,
        GCInputButtonHome
    ]
    var fields: [String: UITextField] = [:]
    var focusedField: UITextField?

    init() {
        super.init(frame: .zero)

        self.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        let dpadGroup = inputGroup(title: NSLocalizedString("gamepadToKeyEditor.group.directionalPad",
                                                            tableName: "Playtools", comment: ""),
                                   buttons: dpadButtons)
        let abxyGroup = inputGroup(title: NSLocalizedString("gamepadToKeyEditor.group.buttons",
                                                            tableName: "Playtools", comment: ""),
                                   buttons: abxyButtons)
        let triggerGroup = inputGroup(title: NSLocalizedString("gamepadToKeyEditor.group.triggers",
                                                               tableName: "Playtools", comment: ""),
                                      buttons: triggerButtons)
        let leftThumbstickGroup = inputGroup(title: NSLocalizedString("gamepadToKeyEditor.group.leftThumbstick",
                                                                      tableName: "Playtools", comment: ""),
                                             buttons: leftThumbstickButtons)
        let rightThumbstickGroup = inputGroup(title: NSLocalizedString("gamepadToKeyEditor.group.rightThumbstick",
                                                                       tableName: "Playtools", comment: ""),
                                              buttons: rightThumbstickButtons)
        let specialGroup = inputGroup(title: NSLocalizedString("gamepadToKeyEditor.group.otherButtons",
                                                               tableName: "Playtools", comment: ""),
                                      buttons: specialButtons)

        var rows: [[UIView]] = []
        if screen.width > screen.height {
            rows = [
                [leftThumbstickGroup, rightThumbstickGroup, triggerGroup],
                [dpadGroup, abxyGroup, specialGroup]
            ]
        } else {
            rows = [
                [leftThumbstickGroup, rightThumbstickGroup],
                [dpadGroup, abxyGroup],
                [triggerGroup, specialGroup]
            ]
        }
        initView(rows: rows)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initView(rows: [[UIView]]) {
        let spacing = CGFloat(3.33).absoluteSize

        var rowStacks: [UIView] = []
        for row in rows {
            let rowStack = UIStackView(arrangedSubviews: row)
            rowStack.axis = .horizontal
            rowStack.alignment = .top
            rowStack.distribution = .equalSpacing
            rowStack.spacing = spacing
            rowStacks.append(rowStack)
        }

        let mainStack = UIStackView(arrangedSubviews: rowStacks)
        mainStack.axis = .vertical
        mainStack.alignment = .center
        mainStack.distribution = .equalSpacing
        mainStack.spacing = spacing
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func inputGroup(title: String, buttons: [String]) -> UIView {
        let fontSize = CGFloat(1.25).absoluteSize

        let groupStack = UIStackView()
        groupStack.axis = .vertical
        groupStack.alignment = .center
        groupStack.spacing = CGFloat(0.41).absoluteSize

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: fontSize)
        groupStack.addArrangedSubview(titleLabel)

        for btn in buttons {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center

            let label = UILabel()
            label.text = buttonLabel(for: btn)
            label.textColor = .white
            label.font = .systemFont(ofSize: fontSize)
            label.widthAnchor.constraint(equalToConstant: CGFloat(10.5).absoluteSize).isActive = true

            let field = UITextField()
            field.text = ""
            field.borderStyle = .roundedRect
            field.widthAnchor.constraint(equalToConstant: CGFloat(7.29).absoluteSize).isActive = true
            field.heightAnchor.constraint(equalToConstant: CGFloat(2.60).absoluteSize).isActive = true
            field.textAlignment = .center
            field.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .medium)
            let tap = UITapGestureRecognizer(target: self, action: #selector(fieldTapped))
            field.addGestureRecognizer(tap)
            fields[btn] = field

            row.addArrangedSubview(label)
            row.addArrangedSubview(field)
            groupStack.addArrangedSubview(row)
        }
        return groupStack
    }

    private func buttonLabel(for alias: String) -> String {
        if let gamepad = GCController.current?.extendedGamepad,
           let button = gamepad.allButtons.first(where: { $0.aliases.first == alias }),
           let label = button.localizedName {
            return label
        }
        if alias.contains("Thumbstick") || alias.contains("Direction Pad") || alias.contains("Button") {
            let parts = alias.split(separator: " ")
            return String(parts[parts.count - 1])
        }
        return alias
    }

    @objc func fieldTapped(_ sender: UITapGestureRecognizer) {
        if let field = sender.view as? UITextField {
            if focusedField == field {
                setKey(KeyCodeNames.leftMouseButton)
            } else {
                focusedField = field
            }
        }
    }

    func focus(_ key: String) {
        guard let field = fields[key] else { return }
        focusedField = field
        field.becomeFirstResponder()
    }

    func setKey(_ key: String) {
        focusedField?.text = key
    }

    func setData(_ data: [GamepadToKey]) {
        for gamepadToKey in data {
            if let field = fields[gamepadToKey.keyName] {
                field.text = gamepadToKey.targetKeyName
            }
        }
    }

    func getData() -> [GamepadToKey] {
        var data: [GamepadToKey] = []
        for (keyName, field) in fields {
            if let targetKeyName = field.text, !targetKeyName.isEmpty {
                data.append(GamepadToKey(keyName: keyName, targetKeyName: targetKeyName))
            }
        }
        return data
    }
}
