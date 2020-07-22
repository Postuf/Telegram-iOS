import Foundation
import UIKit
import AppBundle
import AsyncDisplayKit
import Display
import SolidRoundedButtonNode
import SwiftSignalKit
import OverlayStatusController
import AnimatedStickerNode
import AccountContext
import TelegramPresentationData
import PresentationDataUtils
import CheckNode

public final class FalseBottomRequirementsScreen: ViewController {
    private let presentationData: PresentationData
    private let context: SharedAccountContext
    
    var buttonPressed: (() -> Void)?
    var setMasterPassword: (() -> Void)?
    var createAnotherAccount: (() -> Void)?
    
    private var node: FalseBottomRequirementsScreenNode {
        return self.displayNode as! FalseBottomRequirementsScreenNode
    }
    
    public init(presentationData: PresentationData, context: SharedAccountContext) {
        self.presentationData = presentationData
        self.context = context
        
        let defaultTheme = NavigationBarTheme(rootControllerTheme: self.presentationData.theme)
        let navigationBarTheme = NavigationBarTheme(buttonColor: defaultTheme.buttonColor, disabledButtonColor: defaultTheme.disabledButtonColor, primaryTextColor: defaultTheme.primaryTextColor, backgroundColor: .clear, separatorColor: .clear, badgeBackgroundColor: defaultTheme.badgeBackgroundColor, badgeStrokeColor: defaultTheme.badgeStrokeColor, badgeTextColor: defaultTheme.badgeTextColor)
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(theme: navigationBarTheme, strings: NavigationBarStrings(back: self.presentationData.strings.Common_Back, close: self.presentationData.strings.Common_Close)))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationPresentation = .modalInLargeLayout
        self.supportedOrientations = ViewControllerSupportedOrientations(regularSize: .all, compactSize: .portrait)
        self.navigationBar?.intrinsicCanTransitionInline = false
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
    }
    
    override public func loadDisplayNode() {
        let displayNode = FalseBottomRequirementsScreenNode(presentationData: self.presentationData, action: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.buttonPressed?()
        })
        
        displayNode.setMasterPassword = { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.setMasterPassword?()
        }
        
        displayNode.createAnotherAccount = { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.createAnotherAccount?()
        }
        
        self.displayNode = displayNode
        self.displayNodeDidLoad()
        
        updateState()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        node.containerLayoutUpdated(layout: layout, navigationHeight: self.navigationHeight, transition: transition)
    }
    
    func didSetMasterPassword() {
        updateState()
    }
    
    private func updateState() {
        let _ = (context.accountManager.transaction { transaction -> (Bool, Bool) in
            let isMasterPasswordSet = transaction.getAccessChallengeData() != .none
            let hasOtherOpenAccounts = transaction.getRecords().count > 1
            return (isMasterPasswordSet, hasOtherOpenAccounts)
        } |> deliverOnMainQueue).start(next: { [weak self] (isMasterPasswordSet, hasOtherOpenAccounts) in
            guard let strongSelf = self else { return }
            
            strongSelf.node.masterPasscodeNode.setIsChecked(isMasterPasswordSet, animated: false)
            
            strongSelf.node.openAccountNode.setIsChecked(hasOtherOpenAccounts, animated: false)
            
            strongSelf.node.inProgress = !(isMasterPasswordSet && hasOtherOpenAccounts)
        })
    }
}

private final class FalseBottomRequirementsScreenNode: ViewControllerTracingNode {
    private let presentationData: PresentationData
    
    let openAccountNode: FalseBottomRequirementNode
    let masterPasscodeNode: FalseBottomRequirementNode
    let buttonNode: SolidRoundedButtonNode
    
    var setMasterPassword: (() -> Void)?
    var createAnotherAccount: (() -> Void)?
    
    var inProgress: Bool = false {
        didSet {
            self.buttonNode.isUserInteractionEnabled = !self.inProgress
            self.buttonNode.alpha = self.inProgress ? 0.6 : 1.0
        }
    }
    
    init(presentationData: PresentationData, action: @escaping () -> Void) {
        self.presentationData = presentationData
        
        let buttonText: String
        
        let textFont = Font.regular(16.0)
        let textColor = self.presentationData.theme.list.itemPrimaryTextColor

        let openAccountAttributedString = NSAttributedString(string: "There is at least one open account on this device", font: textFont, textColor: textColor)
        let masterPasscodeAttributedString = NSAttributedString(string: "Master passcode is set up", font: textFont, textColor: textColor)
        
        buttonText = "Continue"
        
        self.openAccountNode = FalseBottomRequirementNode(presentationData: presentationData, attributedString: openAccountAttributedString)
        self.openAccountNode.displaysAsynchronously = false
        
        self.masterPasscodeNode = FalseBottomRequirementNode(presentationData: presentationData, attributedString: masterPasscodeAttributedString)
        self.masterPasscodeNode.displaysAsynchronously = false
        
        self.buttonNode = SolidRoundedButtonNode(title: buttonText, theme: SolidRoundedButtonTheme(backgroundColor: self.presentationData.theme.list.itemCheckColors.fillColor, foregroundColor: self.presentationData.theme.list.itemCheckColors.foregroundColor), height: 50.0, cornerRadius: 10.0, gloss: false)
        self.buttonNode.isHidden = buttonText.isEmpty
        
        super.init()
        
        self.backgroundColor = self.presentationData.theme.list.plainBackgroundColor
        
        self.addSubnode(self.openAccountNode)
        self.addSubnode(self.masterPasscodeNode)
        self.addSubnode(self.buttonNode)
        
        self.openAccountNode.addTarget(self, action: #selector(didTapOpenAccount), forControlEvents: .touchUpInside)
        self.masterPasscodeNode.addTarget(self, action: #selector(didTapMasterPassword), forControlEvents: .touchUpInside)
        
        self.buttonNode.pressed = {
            action()
        }
        
        self.inProgress = true
    }
    
    override func didLoad() {
        super.didLoad()
    }
    
    func containerLayoutUpdated(layout: ContainerViewLayout, navigationHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        let sideInset: CGFloat = 32.0
        let buttonSideInset: CGFloat = 48.0
        let titleSpacing: CGFloat = 19.0
        let buttonHeight: CGFloat = 50.0
        let checkSize = CGSize(width: 32.0, height: 32.0)
        
        let openAccountSize = self.openAccountNode.updateLayout(width: layout.size.width - sideInset * 2.0)
        let masterPasscodeSize = self.masterPasscodeNode.updateLayout(width: layout.size.width - sideInset * 2.0)
        
        let contentHeight = openAccountSize.height + titleSpacing + masterPasscodeSize.height
        var contentVerticalOrigin = floor((layout.size.height - contentHeight / 2.0) / 2.0)
        
        let minimalBottomInset: CGFloat = 60.0
        let bottomInset = layout.intrinsicInsets.bottom + minimalBottomInset
        
        let buttonWidth = layout.size.width - buttonSideInset * 2.0
        
        let buttonFrame = CGRect(origin: CGPoint(x: floor((layout.size.width - buttonWidth) / 2.0), y: layout.size.height - bottomInset - buttonHeight), size: CGSize(width: buttonWidth, height: buttonHeight))
        transition.updateFrame(node: self.buttonNode, frame: buttonFrame)
        self.buttonNode.updateLayout(width: buttonFrame.width, transition: transition)
        
        var maxContentVerticalOrigin = buttonFrame.minY - 12.0 - contentHeight
        
        contentVerticalOrigin = min(contentVerticalOrigin, maxContentVerticalOrigin)
        
        
        let openAccountFrame = CGRect(origin: CGPoint(x: sideInset, y: contentVerticalOrigin), size: openAccountSize)
        transition.updateFrameAdditive(node: self.openAccountNode, frame: openAccountFrame)
        
        let masterPasscodeFrame = CGRect(origin: CGPoint(x: sideInset, y: openAccountFrame.maxY + titleSpacing), size: masterPasscodeSize)
        transition.updateFrameAdditive(node: self.masterPasscodeNode, frame: masterPasscodeFrame)
    }
    
    @objc private func didTapOpenAccount() {
        guard !self.openAccountNode.isChecked else { return }
        
        self.createAnotherAccount?()
    }
    
    @objc private func didTapMasterPassword() {
        guard !self.masterPasscodeNode.isChecked else { return }
        
        self.setMasterPassword?()
    }
}

final class FalseBottomRequirementNode: ASControlNode {
    private let textNode: ImmediateTextNode
    private let checkNode: CheckNode
    
    public private(set) var isChecked: Bool = false

    init(presentationData: PresentationData, attributedString: NSAttributedString) {
        self.textNode = ImmediateTextNode()
        self.textNode.displaysAsynchronously = false
        self.textNode.attributedText = attributedString
        self.textNode.maximumNumberOfLines = 0
        self.textNode.lineSpacing = 0.1
        self.textNode.textAlignment = .left
        
        self.checkNode = CheckNode(strokeColor: presentationData.theme.list.itemCheckColors.strokeColor, fillColor: presentationData.theme.list.itemSwitchColors.positiveColor, foregroundColor: presentationData.theme.list.itemCheckColors.foregroundColor, style: .plain)
        
        super.init()
        
        self.backgroundColor = presentationData.theme.list.plainBackgroundColor
        
        self.addSubnode(self.textNode)
        self.addSubnode(self.checkNode)
    }
    
    func setIsChecked(_ isChecked: Bool, animated: Bool) {
        self.isChecked = isChecked
        self.checkNode.setIsChecked(isChecked, animated: animated)
    }
    
    func updateLayout(width: CGFloat) -> CGSize {
        let spacing: CGFloat = 12.0

        let checkSize = CGSize(width: 32.0, height: 32.0)

        let textWidth = width - spacing - checkSize.width
        
        let textSize = self.textNode.updateLayout(CGSize(width: textWidth, height: .greatestFiniteMagnitude))
        
        let height: CGFloat = max(checkSize.height, textSize.height)
        
        self.textNode.frame = CGRect(origin: CGPoint(x: spacing + checkSize.width, y: (height - textSize.height) / 2), size: textSize)
        
        self.checkNode.frame = CGRect(origin: CGPoint(x: 0, y: (height - checkSize.height) / 2), size: checkSize)
        
        return CGSize(width: width, height: height)
    }
}
