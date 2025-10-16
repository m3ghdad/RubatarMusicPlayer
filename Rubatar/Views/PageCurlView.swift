//
//  PageCurlView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/16/25.
//

import SwiftUI
import UIKit

struct PageCurlView<Content: View>: UIViewControllerRepresentable {
    @Binding var currentPage: Int
    let pageCount: Int
    let content: (Int) -> Content
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [UIPageViewController.OptionsKey.spineLocation: NSNumber(value: UIPageViewController.SpineLocation.min.rawValue)]
        )
        
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        
        // Set initial page
        if pageCount > 0 {
            let initialViewController = context.coordinator.viewControllers[currentPage]
            pageViewController.setViewControllers(
                [initialViewController],
                direction: .forward,
                animated: false
            )
        }
        
        return pageViewController
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        if let currentViewController = pageViewController.viewControllers?.first as? UIHostingController<Content>,
           let currentIndex = context.coordinator.viewControllers.firstIndex(of: currentViewController),
           currentIndex != currentPage {
            let direction: UIPageViewController.NavigationDirection = currentPage > currentIndex ? .forward : .reverse
            let viewController = context.coordinator.viewControllers[currentPage]
            pageViewController.setViewControllers(
                [viewController],
                direction: direction,
                animated: true
            )
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let parent: PageCurlView
        var viewControllers: [UIHostingController<Content>] = []
        
        init(_ parent: PageCurlView) {
            self.parent = parent
            super.init()
            
            // Create view controllers for each page
            for index in 0..<parent.pageCount {
                let hostingController = UIHostingController(rootView: parent.content(index))
                hostingController.view.backgroundColor = .clear
                viewControllers.append(hostingController)
            }
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = viewControllers.firstIndex(of: viewController as! UIHostingController<Content>),
                  index > 0 else {
                return nil
            }
            return viewControllers[index - 1]
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = viewControllers.firstIndex(of: viewController as! UIHostingController<Content>),
                  index < viewControllers.count - 1 else {
                return nil
            }
            return viewControllers[index + 1]
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            if completed,
               let currentViewController = pageViewController.viewControllers?.first,
               let index = viewControllers.firstIndex(of: currentViewController as! UIHostingController<Content>) {
                parent.currentPage = index
            }
        }
    }
}

