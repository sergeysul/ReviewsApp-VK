import UIKit

final class ReviewsViewController: UIViewController {

    private lazy var reviewsView = makeReviewsView()
    private let viewModel: ReviewsViewModel

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = reviewsView
        title = "Отзывы"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        viewModel.getReviews()
    }
    
    deinit {
        reviewsView.tableView.delegate = nil
        reviewsView.tableView.dataSource = nil
    }

}

// MARK: - Private

private extension ReviewsViewController {

    func makeReviewsView() -> ReviewsView {
        let reviewsView = ReviewsView()
        reviewsView.tableView.delegate = viewModel
        reviewsView.tableView.dataSource = viewModel
        return reviewsView
    }

    func setupViewModel() {
        viewModel.onStateChange = { [weak reviewsView] state, change in
            guard let tableView = reviewsView?.tableView else { return }
            switch change {
            case .reloadData:
                tableView.reloadData()
            case .reloadRows(let indices):
                let indexPaths = indices.map { IndexPath(row: $0, section: 0) }
                tableView.reloadRows(at: indexPaths, with: .automatic)
            }
        }
    }
}
