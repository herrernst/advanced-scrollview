//
//  UIScrollViewController.swift
//  
//
//  Created by Dmytro Anokhin on 24/06/2021.
//

#if !os(macOS)

import UIKit
import SwiftUI


protocol UIScrollViewControllerDelegate: NSObject {

    func scrollViewController(_ scrollViewController: UIScrollViewController, zoomScaleDidChange zoomScale: CGFloat)
}


final class UIScrollViewController: UIViewController, UIScrollViewDelegate {

    let contentViewController: UIViewController

    let minimumZoomScale: CGFloat

    let maximumZoomScale: CGFloat

    private(set) var zoomScale: CGFloat

    let isZoomRelative: Bool

    let isScrollIndicatorVisible: Bool

    init(contentViewController: UIViewController,
         minimumZoomScale: CGFloat,
         maximumZoomScale: CGFloat,
         zoomScale: CGFloat,
         isZoomRelative: Bool,
         isScrollIndicatorVisible: Bool) {
        self.contentViewController = contentViewController
        self.minimumZoomScale = minimumZoomScale
        self.maximumZoomScale = maximumZoomScale
        self.zoomScale = zoomScale
        self.isZoomRelative = isZoomRelative
        self.isScrollIndicatorVisible = isScrollIndicatorVisible

        super.init(nibName: nil, bundle: nil)
    }

    weak var delegate: UIScrollViewControllerDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = maximumZoomScale
        scrollView.showsHorizontalScrollIndicator = isScrollIndicatorVisible
        scrollView.showsVerticalScrollIndicator = isScrollIndicatorVisible

        addChild(contentViewController)
        contentViewController.view.sizeToFit()

        scrollView.addSubview(contentViewController.view)

        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false

        topConstraint = contentViewController.view.topAnchor.constraint(equalTo: scrollView.topAnchor)
        leadingConstraint = contentViewController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
        bottomConstraint = contentViewController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        trailingConstraint = contentViewController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)

        NSLayoutConstraint.activate([ topConstraint, leadingConstraint, bottomConstraint, trailingConstraint])

        contentViewController.didMove(toParent: self)

        self.view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.zoomToFit()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { _ in
            self.zoomToFit()
        }
        completion: { _ in
        }
    }

    func scrollTo(_ rect: CGRect, animated: Bool) {
        guard isViewLoaded else {
            return
        }

        scrollView.scrollRectToVisible(rect, animated: animated)
    }

    var scrollView: UIScrollView {
        view as! UIScrollView
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentViewController.view
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        zoomScale = scrollView.zoomScale / (zoomScaleMultiplier != 0.0 ? zoomScaleMultiplier : 1.0)
        updateConstraintsToMatchZoomScale()

        delegate?.scrollViewController(self, zoomScaleDidChange: zoomScale)
    }

    // MARK: - Private

    private var topConstraint: NSLayoutConstraint!
    private var leadingConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    private func updateConstraintsToMatchZoomScale() {
        let contentViewSize = contentViewController.view.sizeThatFits(.greatestFiniteMagnitude)
        let scrollViewSize = scrollView.frame.size

        let horizontalOffset = max((scrollViewSize.width - scrollView.zoomScale * contentViewSize.width) * 0.5, 0.0)
        let verticalOffset = max((scrollViewSize.height - scrollView.zoomScale * contentViewSize.height) * 0.5, 0.0)

        topConstraint.constant = verticalOffset
        leadingConstraint.constant = horizontalOffset
        bottomConstraint.constant = verticalOffset
        trailingConstraint.constant = horizontalOffset

        view.layoutIfNeeded()
    }

    /// Multiplier used to calculate zoom scale relative to the frame
    private var zoomScaleMultiplier: CGFloat = 1.0

    private func zoomToFit() {
        guard isZoomRelative else {
            return
        }

        let contentViewSize = contentViewController.view.sizeThatFits(.greatestFiniteMagnitude)
        let scrollViewSize = scrollView.frame.size

        var newZoomScaleMultiplier = min(scrollViewSize.width / contentViewSize.width,
                                         scrollViewSize.height / contentViewSize.height)

        scrollView.minimumZoomScale = minimumZoomScale * newZoomScaleMultiplier
        scrollView.maximumZoomScale = maximumZoomScale * newZoomScaleMultiplier

        if zoomScaleMultiplier == newZoomScaleMultiplier { // Add a small delta to force update
            newZoomScaleMultiplier += 0.0001
        }

        zoomScaleMultiplier = newZoomScaleMultiplier
        scrollView.zoomScale = zoomScale * newZoomScaleMultiplier
    }
}


#endif

