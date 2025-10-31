//
//  PageCurlView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/16/25.
//

import SwiftUI
import UIKit

struct PageCurlView<Content: View>: View {
    @Binding var currentPage: Int
    let pageCount: Int
    let isRTL: Bool // Add RTL support
    let content: (Int) -> Content
    let contentVersion: Int // Version number that changes when content should update
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        PageCurlViewControllerWrapper(
            currentPage: $currentPage,
            pageCount: pageCount,
            isRTL: isRTL,
            colorScheme: colorScheme,
            content: content,
            contentVersion: contentVersion
        )
    }
}

struct PageCurlViewControllerWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding var currentPage: Int
    let pageCount: Int
    let isRTL: Bool
    let colorScheme: ColorScheme
    let content: (Int) -> Content
    let contentVersion: Int // Version number that changes when content should update
    
    func makeUIViewController(context: Context) -> PageCurlHostController<Content> {
        let controller = PageCurlHostController(
            pageCount: pageCount,
            currentPage: currentPage,
            isRTL: isRTL,
            colorScheme: colorScheme,
            contentBuilder: content
        )
        
        controller.onPageChange = { newPage in
            DispatchQueue.main.async {
                currentPage = newPage
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PageCurlHostController<Content>, context: Context) {
        if uiViewController.currentPage != currentPage {
            uiViewController.setPage(currentPage, animated: true)
        }
        
        // Update background color when color scheme changes
        uiViewController.updateColorScheme(colorScheme)
        
        // Update RTL mode if it changed
        uiViewController.updateRTL(isRTL)
        
        // Rebuild view controllers when content version changes
        if uiViewController.contentVersion != contentVersion {
            uiViewController.rebuildViewControllers(contentBuilder: content, contentVersion: contentVersion)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
    }
}

// Custom container that manages bidirectional page curl
class PageCurlHostController<Content: View>: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    private var pageViewController: UIPageViewController!
    private var viewControllers: [UIHostingController<Content>] = []
    private var isReverse: Bool = false
    private var colorScheme: ColorScheme
    private var isRTL: Bool
    
    let pageCount: Int
    var currentPage: Int
    var onPageChange: ((Int) -> Void)?
    private let contentBuilder: (Int) -> Content
    var contentVersion: Int = 0
    
    init(pageCount: Int, currentPage: Int, isRTL: Bool, colorScheme: ColorScheme, contentBuilder: @escaping (Int) -> Content) {
        self.pageCount = pageCount
        self.currentPage = currentPage
        self.isRTL = isRTL
        self.colorScheme = colorScheme
        self.contentBuilder = contentBuilder
        super.init(nibName: nil, bundle: nil)
        
        setupViewControllers()
        setupPageViewController(isReverse: isRTL) // Start with RTL state
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViewControllers() {
        viewControllers.removeAll()
        for index in 0..<pageCount {
            let hostingController = UIHostingController(rootView: contentBuilder(index))
            // Set background color based on color scheme - this is the "back" of the page during curl
            let backgroundColor = colorScheme == .dark ? UIColor.black : .white
            hostingController.view.backgroundColor = backgroundColor
            // Also set the layer background for the curl effect
            hostingController.view.layer.backgroundColor = backgroundColor.cgColor
            hostingController.view.isOpaque = true
            viewControllers.append(hostingController)
        }
    }
    
    func rebuildViewControllers(contentBuilder: @escaping (Int) -> Content, contentVersion: Int) {
        self.contentVersion = contentVersion
        let savedCurrentPage = currentPage
        
        // Rebuild all view controllers with new content
        setupViewControllers()
        
        // Restore current page
        if savedCurrentPage < viewControllers.count {
            pageViewController.setViewControllers(
                [viewControllers[savedCurrentPage]],
                direction: .forward,
                animated: false,
                completion: nil
            )
            currentPage = savedCurrentPage
        }
    }
    
    func updateColorScheme(_ newColorScheme: ColorScheme) {
        guard colorScheme != newColorScheme else { return }
        colorScheme = newColorScheme
        
        // Update background color for all view controllers and the page view controller
        let backgroundColor = colorScheme == .dark ? UIColor.black : .white
        view.backgroundColor = backgroundColor
        view.layer.backgroundColor = backgroundColor.cgColor
        
        if let pageVC = pageViewController {
            // Force interface style to match color scheme
            if colorScheme == .dark {
                pageVC.overrideUserInterfaceStyle = .dark
            } else {
                pageVC.overrideUserInterfaceStyle = .light
            }
            
            pageVC.view.backgroundColor = backgroundColor
            pageVC.view.layer.backgroundColor = backgroundColor.cgColor
            setBackgroundRecursively(pageVC.view, color: backgroundColor)
        }
        
        for controller in viewControllers {
            controller.view.backgroundColor = backgroundColor
            controller.view.layer.backgroundColor = backgroundColor.cgColor
            controller.view.isOpaque = true
        }
    }
    
    func updateRTL(_ newRTL: Bool) {
        guard isRTL != newRTL else { return }
        isRTL = newRTL
        
        // Rebuild page view controller with new direction
        setupPageViewController(isReverse: isRTL)
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageViewController.didMove(toParent: self)
        
        // Reset to current page
        if currentPage < viewControllers.count {
            pageViewController.setViewControllers(
                [viewControllers[currentPage]],
                direction: .forward,
                animated: false,
                completion: nil
            )
        }
    }
    
    private func setupPageViewController(isReverse: Bool) {
        // Remove old page view controller if exists
        if let oldPageVC = pageViewController {
            oldPageVC.willMove(toParent: nil)
            oldPageVC.view.removeFromSuperview()
            oldPageVC.removeFromParent()
        }
        
        // Create new page view controller with appropriate spine location
        // For RTL: spine on max (right side), so page flips from left
        // For LTR: spine on min (left side), so page flips from right
        let spineLocation: UIPageViewController.SpineLocation = isRTL ? .max : .min
        
        pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [
                UIPageViewController.OptionsKey.spineLocation: NSNumber(value: spineLocation.rawValue)
            ]
        )
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.isDoubleSided = false
        
        // Force dark/light interface style
        if colorScheme == .dark {
            pageViewController.overrideUserInterfaceStyle = .dark
        } else {
            pageViewController.overrideUserInterfaceStyle = .light
        }
        
        // Force black background for the page curl effect in dark mode
        let backgroundColor = colorScheme == .dark ? UIColor.black : .white
        pageViewController.view.backgroundColor = backgroundColor
        
        // Also set the background color for the underlying layer
        if let scrollView = pageViewController.view.subviews.first(where: { $0 is UIScrollView }) {
            scrollView.backgroundColor = backgroundColor
        }
        
        self.isReverse = isReverse
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background colors for dark mode support - black for back of page curl
        let backgroundColor = colorScheme == .dark ? UIColor.black : .white
        view.backgroundColor = backgroundColor
        view.layer.backgroundColor = backgroundColor.cgColor
        view.isOpaque = true
        
        // Force dark/light interface style on the page view controller
        if colorScheme == .dark {
            pageViewController.overrideUserInterfaceStyle = .dark
        } else {
            pageViewController.overrideUserInterfaceStyle = .light
        }
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageViewController.view.backgroundColor = backgroundColor
        pageViewController.view.layer.backgroundColor = backgroundColor.cgColor
        pageViewController.view.isOpaque = true
        
        // Recursively set background color on all subviews to ensure the curl effect is dark
        setBackgroundRecursively(pageViewController.view, color: backgroundColor)
        
        pageViewController.didMove(toParent: self)
        
        if currentPage < viewControllers.count {
            pageViewController.setViewControllers(
                [viewControllers[currentPage]],
                direction: .forward,
                animated: false,
                completion: nil
            )
        }
    }
    
    // Helper to set background color recursively on all subviews
    private func setBackgroundRecursively(_ view: UIView, color: UIColor) {
        // Only set background for non-content views
        // Skip views that are part of our hosting controllers (they should keep their own backgrounds)
        let isHostingView = viewControllers.contains { $0.view == view }
        
        if !isHostingView {
            view.backgroundColor = color
            view.layer.backgroundColor = color.cgColor
            view.isOpaque = true
        }
        
        for subview in view.subviews {
            setBackgroundRecursively(subview, color: color)
        }
    }
    
    func setPage(_ page: Int, animated: Bool) {
        guard page >= 0 && page < pageCount && page != currentPage else { return }
        
        let direction = page > currentPage
        
        // If direction changed, rebuild page view controller with new spine location
        if direction != !isReverse {
            setupPageViewController(isReverse: !direction)
            
            addChild(pageViewController)
            view.addSubview(pageViewController.view)
            pageViewController.view.frame = view.bounds
            pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            pageViewController.didMove(toParent: self)
        }
        
        let targetVC = viewControllers[page]
        let navDirection: UIPageViewController.NavigationDirection = direction ? .forward : .reverse
        
        pageViewController.setViewControllers(
            [targetVC],
            direction: navDirection,
            animated: animated
        ) { [weak self] _ in
            self?.currentPage = page
            self?.onPageChange?(page)
        }
    }
    
    // MARK: - UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController as! UIHostingController<Content>) else {
            return nil
        }
        
        // In RTL mode (spine on right), "before" means higher index (next page)
        // In LTR mode (spine on left), "before" means lower index (previous page)
        let targetIndex = isRTL ? index + 1 : index - 1
        
        guard targetIndex >= 0 && targetIndex < viewControllers.count else {
            return nil
        }
        
        // Ensure we're using the correct spine direction
        let shouldBeReverse = isRTL
        if isReverse != shouldBeReverse {
            setupPageViewController(isReverse: shouldBeReverse)
            addChild(self.pageViewController)
            view.addSubview(self.pageViewController.view)
            self.pageViewController.view.frame = view.bounds
            self.pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.pageViewController.didMove(toParent: self)
            
            // Set current page on new controller
            self.pageViewController.setViewControllers(
                [viewController],
                direction: .forward,
                animated: false,
                completion: nil
            )
        }
        
        return viewControllers[targetIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController as! UIHostingController<Content>) else {
            return nil
        }
        
        // In RTL mode (spine on right), "after" means lower index (previous page)
        // In LTR mode (spine on left), "after" means higher index (next page)
        let targetIndex = isRTL ? index - 1 : index + 1
        
        guard targetIndex >= 0 && targetIndex < viewControllers.count else {
            return nil
        }
        
        // Ensure we're using the correct spine direction
        let shouldBeReverse = isRTL
        if isReverse != shouldBeReverse {
            setupPageViewController(isReverse: shouldBeReverse)
            addChild(self.pageViewController)
            view.addSubview(self.pageViewController.view)
            self.pageViewController.view.frame = view.bounds
            self.pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.pageViewController.didMove(toParent: self)
            
            // Set current page on new controller
            self.pageViewController.setViewControllers(
                [viewController],
                direction: .forward,
                animated: false,
                completion: nil
            )
        }
        
        return viewControllers[targetIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let currentViewController = pageViewController.viewControllers?.first,
           let index = viewControllers.firstIndex(of: currentViewController as! UIHostingController<Content>) {
            currentPage = index
            onPageChange?(index)
        }
    }
}
