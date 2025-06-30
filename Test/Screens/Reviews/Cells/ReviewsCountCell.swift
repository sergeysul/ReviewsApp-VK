import UIKit

// MARK: - ReviewsCountCellConfig

struct ReviewsCountCellConfig {
    static let reuseId = String(describing: ReviewsCountCellConfig.self)
    let count: Int
}

extension ReviewsCountCellConfig: TableCellConfig {
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewsCountCell else { return }
        cell.countLabel.text = "\(count) отзывов"
    }

    func height(with size: CGSize) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - ReviewsCountCell

final class ReviewsCountCell: UITableViewCell {
    fileprivate let countLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none

        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.textAlignment = .center
        countLabel.font = .systemFont(ofSize: 14)
        countLabel.textColor = .gray

        contentView.addSubview(countLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            countLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            countLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
}


