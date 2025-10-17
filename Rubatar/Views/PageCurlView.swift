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
    let content: (Int) -> Content
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        PageCurlViewControllerWrapper(
            currentPage: $currentPage,
            pageCount: pageCount,
            colorScheme: colorScheme,
            content: content
        )
    }
}

struct PageCurlViewControllerWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding var currentPage: Int
    let pageCount: Int
    let colorScheme: ColorScheme
    let content: (Int) -> Content
    
    func makeUIViewController(context: Context) -> PageCurlHostController<Content> {
        let controller = PageCurlHostController(
            pageCount: pageCount,
            currentPage: currentPage,
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
    
    let pageCount: Int
    var currentPage: Int
    var onPageChange: ((Int) -> Void)?
    private let contentBuilder: (Int) -> Content
    
    init(pageCount: Int, currentPage: Int, colorScheme: ColorScheme, contentBuilder: @escaping (Int) -> Content) {
        self.pageCount = pageCount
        self.currentPage = currentPage
        self.colorScheme = colorScheme
        self.contentBuilder = contentBuilder
        super.init(nibName: nil, bundle: nil)
        
        setupViewControllers()
        setupPageViewController(isReverse: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViewControllers() {
        for index in 0..<pageCount {
            let hostingController = UIHostingController(rootView: contentBuilder(index))
            // Set background color based on color scheme - this is the "back" of the page during curl
            hostingController.view.backgroundColor = colorScheme == .dark ? UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1.0) : .white
            viewControllers.append(hostingController)
        }
    }
    
    func updateColorScheme(_ newColorScheme: ColorScheme) {
        guard colorScheme != newColorScheme else { return }
        colorScheme = newColorScheme
        
        // Update background color for all view controllers
        let backgroundColor = colorScheme == .dark ? UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1.0) : .white
        for controller in viewControllers {
            controller.view.backgroundColor = backgroundColor
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
        let spineLocation: UIPageViewController.SpineLocation = isReverse ? .max : .min
        
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
        
        self.isReverse = isReverse
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
        guard let index = viewControllers.firstIndex(of: viewController as! UIHostingController<Content>),
              index > 0 else {
            return nil
        }
        
        // Going backward - ensure we're using reverse spine
        if !isReverse {
            setupPageViewController(isReverse: true)
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
        
        return viewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController as! UIHostingController<Content>),
              index < viewControllers.count - 1 else {
            return nil
        }
        
        // Going forward - ensure we're using forward spine
        if isReverse {
            setupPageViewController(isReverse: false)
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
        
        return viewControllers[index + 1]
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
