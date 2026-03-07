//
//  Draggable.swift
//  PlayTools
//
//  Created by 许沂聪 on 2024/6/2.
//

import Foundation

class DraggableButtonElement: Element {
    var mode = DraggableMode.mouseCursorHidden
    var isFocus = false
    var changeModeButton: UIView?
    var changeModeLabel: UILabel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        createChangeModeButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.clipsToBounds = false
        createChangeModeButton()
    }

    override func update() {
        super.update()
        titleEdgeInsets = UIEdgeInsets(top: frame.height / 2, left: 0, bottom: 0, right: 0)
        guard let child = (model as? DraggableButtonModel)?.childButton?.button else {
            return
        }
        let buttonSize = frame.width / 3
        let coord = (frame.width - buttonSize) / 2
        child.frame = CGRect(x: coord, y: coord, width: buttonSize, height: buttonSize)
        child.layer.cornerRadius = 0.5 * child.bounds.size.width

        if let changeModeButton = self.changeModeButton {
            let buttonWidth = frame.width
            let buttonHeight = CGFloat(2.75).absoluteSize
            let spaceHeight = CGFloat(10)
            let buttonX = CGFloat(0)
            let buttonY = CGFloat(0) - spaceHeight - buttonHeight
            changeModeButton.frame = CGRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight)
        }
    }

    override func focus(_ focus: Bool) {
        super.focus(focus)
        self.isFocus = focus
        self.changeModeButton?.isHidden = !isFocus || !mode.isMouseType
    }

    // Since the change mode button is outside its parent's bounds,
    // we need to override this method to ensure it receives click events
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let outsideView = self.changeModeButton, !outsideView.isHidden && outsideView.frame.contains(point) {
            return true
        }
        return super.point(inside: point, with: event)
    }

    func createChangeModeButton() {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: CGFloat(1.25).absoluteSize)
        label.textColor = UIColor.white
        label.textAlignment = .center

        let icon = UIImageView(image: UIImage(systemName: "arrow.2.circlepath"))
        icon.tintColor = UIColor.white
        icon.widthAnchor.constraint(equalToConstant: CGFloat(1.5).absoluteSize).isActive = true
        icon.heightAnchor.constraint(equalToConstant: CGFloat(1.5).absoluteSize).isActive = true

        let spacer1 = UIView()
        spacer1.widthAnchor.constraint(equalToConstant: CGFloat(1.25).absoluteSize).isActive = true
        let spacer2 = UIView()
        spacer2.widthAnchor.constraint(equalToConstant: CGFloat(0.5).absoluteSize).isActive = true
        let spacer3 = UIView()
        spacer3.widthAnchor.constraint(equalToConstant: CGFloat(1.25).absoluteSize).isActive = true

        let hStackView = UIStackView(arrangedSubviews: [spacer1, label, spacer2, icon, spacer3])
        hStackView.axis = .horizontal
        hStackView.alignment = .center
        hStackView.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        hStackView.layer.cornerRadius = 10
        hStackView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(changeModeButtonTapped(_:)))
        hStackView.addGestureRecognizer(gesture)

        let vStackView = UIStackView(arrangedSubviews: [hStackView])
        vStackView.axis = .vertical
        vStackView.alignment = .center

        self.addSubview(vStackView)
        self.changeModeButton = vStackView
        self.changeModeLabel = label
    }

    @objc func changeModeButtonTapped(_ sender: UITapGestureRecognizer) {
        (model as? DraggableButtonModel)?.switchToNextMode()
    }

    func setMode(mode: DraggableMode) {
        self.mode = mode
        self.changeModeButton?.isHidden = !isFocus || !mode.isMouseType

        var displayName: String
        if mode == .mouseCursorHidden {
            displayName = NSLocalizedString("keymappingEditor.draggableButton.mode1",
                                            tableName: "Playtools", value: "Mode 1", comment: "")
        } else if mode == .mouseCursorVisible {
            displayName = NSLocalizedString("keymappingEditor.draggableButton.mode2",
                                            tableName: "Playtools", value: "Mode 2", comment: "")
        } else {
            displayName = "Unknown"
        }
        self.changeModeLabel?.text = displayName
    }
}
