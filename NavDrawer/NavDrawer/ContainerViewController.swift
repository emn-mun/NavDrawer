import UIKit
import QuartzCore

enum SlideOutState {
  case bothCollapsed
  case leftPanelExpanded
  case rightPanelExpanded
}

class ContainerViewController: UIViewController {
  
  let centerPanelExpandedOffset: CGFloat = 60
  
  var centerNavigationController: UINavigationController!
  var centerViewController: CenterViewController!
  var currentState: SlideOutState = .bothCollapsed {
    didSet {
      let shouldShowShadow = currentState != .bothCollapsed
      showShadowForCenterViewController(shouldShowShadow)
    }
  }
  var leftViewController: SidePanelViewController?
  var rightViewController: SidePanelViewController?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    centerViewController = UIStoryboard.centerViewController()
    centerViewController.delegate = self
    
    // wrap the centerViewController in a navigation controller, so we can push views to it
    // and display bar button items in the navigation bar
    centerNavigationController = UINavigationController(rootViewController: centerViewController)
    view.addSubview(centerNavigationController.view)
    addChildViewController(centerNavigationController)
    
    centerNavigationController.didMove(toParentViewController: self)
    
    let panGestureRecogniser = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
    centerNavigationController.view.addGestureRecognizer(panGestureRecogniser)
  }
  
}

extension ContainerViewController: UIGestureRecognizerDelegate {
  func handlePanGesture(recognizer: UIPanGestureRecognizer) {
    let gestureIsDraggingFromLeftToRight = recognizer.velocity(in: view).x > 0
    switch recognizer.state {
    case .began:
      if currentState == .bothCollapsed {
        if gestureIsDraggingFromLeftToRight {
          addLeftPanelViewController()
        } else {
          addRightPanelViewController()
        }
        showShadowForCenterViewController(true)
      }
    case .changed:
      recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translation(in: view).x
      recognizer.setTranslation(.zero, in: view)
    case .ended:
      if (leftViewController != nil) {
        // animate the side panel open or closed based on whether the view has moved more or less than halfway
        let hasMovedGreaterThanHalfway = recognizer.view!.center.x > view.bounds.size.width
        animateLeftPanel(shouldExpand: hasMovedGreaterThanHalfway)
      } else if (rightViewController != nil) {
        let hasMovedGreaterThanHalfway = recognizer.view!.center.x < 0
        animateRightPanel(shouldExpand: hasMovedGreaterThanHalfway)
      }
    default:
      break
    }
  }
}

extension ContainerViewController: CenterViewControllerDelegate {
  func toggleLeftPanel() {
    let notAlreadyExpanded = currentState != .leftPanelExpanded
    if notAlreadyExpanded {
      addLeftPanelViewController()
    }
    animateLeftPanel(shouldExpand: notAlreadyExpanded)
  }
  
  func toggleRightPanel() {
    let notAlreadyExpanded = currentState != .rightPanelExpanded
    if notAlreadyExpanded {
      addRightPanelViewController()
    }
    animateRightPanel(shouldExpand: notAlreadyExpanded)
  }
  
  func collapseSidePanels() {
    switch currentState {
    case .leftPanelExpanded:
      toggleLeftPanel()
    case .rightPanelExpanded:
      toggleRightPanel()
    default:
      break
    }
  }
  
  func addLeftPanelViewController() {
    if leftViewController == nil {
      leftViewController = UIStoryboard.leftViewController()
      leftViewController?.animals = Animal.allCats()
      addChildSidePanelController(leftViewController!)
    }
  }
  
  func addChildSidePanelController(_ sidePanelViewController: SidePanelViewController) {
    sidePanelViewController.delegate = centerViewController
    view.insertSubview(sidePanelViewController.view, at: 0)
    addChildViewController(sidePanelViewController)
    sidePanelViewController.didMove(toParentViewController: self)
  }
  
  func addRightPanelViewController() {
    if (rightViewController == nil) {
      rightViewController = UIStoryboard.rightViewController()
      rightViewController!.animals = Animal.allDogs()
      
      addChildSidePanelController(rightViewController!)
    }
  }
  
  func animateLeftPanel(shouldExpand: Bool) {
    if shouldExpand {
      currentState = .leftPanelExpanded
      animateCenterPanelXPosition(targetPosition: centerNavigationController.view.frame.width - centerPanelExpandedOffset)
    } else {
      animateCenterPanelXPosition(targetPosition: 0, completion: { result in
        self.currentState = .bothCollapsed
        self.leftViewController?.view.removeFromSuperview()
        self.leftViewController = nil
      })
    }
  }
  
  func animateRightPanel(shouldExpand: Bool) {
    if (shouldExpand) {
      currentState = .rightPanelExpanded
      
      animateCenterPanelXPosition(targetPosition: -centerNavigationController.view.frame.width + centerPanelExpandedOffset)
    } else {
      animateCenterPanelXPosition(targetPosition: 0) { _ in
        self.currentState = .bothCollapsed
        
        self.rightViewController!.view.removeFromSuperview()
        self.rightViewController = nil;
      }
    }
  }
  
  func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)? = nil) {
    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: { 
      self.centerNavigationController.view.frame.origin.x = targetPosition
    }, completion: completion)
  }
  
  func showShadowForCenterViewController(_ shouldShow: Bool) {
    if shouldShow {
      centerNavigationController.view.layer.shadowOpacity = 0.8
    } else {
      centerNavigationController.view.layer.shadowOpacity = 0.0
    }
  }
}

private extension UIStoryboard {
  class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: Bundle.main) }
  
  class func leftViewController() -> SidePanelViewController? {
    return mainStoryboard().instantiateViewController(withIdentifier: "LeftViewController") as? SidePanelViewController
  }
  
  class func rightViewController() -> SidePanelViewController? {
    return mainStoryboard().instantiateViewController(withIdentifier: "RightViewController") as? SidePanelViewController
  }
  
  class func centerViewController() -> CenterViewController? {
    return mainStoryboard().instantiateViewController(withIdentifier: "CenterViewController") as? CenterViewController
  }
  
}
