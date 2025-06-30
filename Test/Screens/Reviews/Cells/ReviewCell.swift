import UIKit

struct ReviewCellConfig {

    static let reuseId = String(describing: ReviewCellConfig.self)
    let id = UUID()
    let reviewText: NSAttributedString
    var maxLines = 3
    let created: NSAttributedString
    let onTapShowMore: (UUID) -> Void
    let avatarImage: UIImage?
    let username: String
    let rating: Int
    let photoURLs: [String]
    weak var ratingRenderer: RatingRenderer?

    var shouldShowShowMoreButton: Bool {
        guard maxLines > 0 else { return false }
        
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = reviewText
        label.font = .text

        let maxWidth = UIScreen.main.bounds.width - 12 - 36 - 10 - 12
        let fullSize = label.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = maxLines
        let limitedSize = label.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        
        return fullSize.height > limitedSize.height
    }
}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }
        cell.usernameLabel.text = username
        cell.avatarImageView.image = avatarImage
        cell.ratingImageView.image = ratingRenderer?.ratingImage(rating)
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created
        cell.config = self
        cell.updateShowMoreButtonVisibility(visible: shouldShowShowMoreButton)
        
        if photoURLs.isEmpty {
            cell.photosStackView.isHidden = true
        } else {
            cell.photosStackView.isHidden = false
            cell.updatePhotos(urls: photoURLs)
        }
    }
    
    func height(with size: CGSize) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - Private

private extension ReviewCellConfig {
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)
}

// MARK: - Cell

final class ReviewCell: UITableViewCell {
    fileprivate var config: ReviewCellConfig?

    let avatarImageView = UIImageView()
    let usernameLabel = UILabel()
    let ratingImageView = UIImageView()
    let reviewTextLabel = UILabel()
    let showMoreButton = UIButton()
    let createdLabel = UILabel()
    let photosStackView = UIStackView()
    
    private let maxPhotos = 5
    private var photoImageViews: [UIImageView] = []
    private var imageLoadUUIDs: [UUID] = []

    private var reviewTextTopWithPhotosConstraint: NSLayoutConstraint!
    private var reviewTextTopWithoutPhotosConstraint: NSLayoutConstraint!
    
    private var showMoreButtonTopConstraint: NSLayoutConstraint!
    private var createdLabelTopWithButtonConstraint: NSLayoutConstraint!
    private var createdLabelTopWithoutButtonConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadUUIDs.forEach { ImageLoader.shared.cancelLoad(for: $0) }
        imageLoadUUIDs.removeAll()
        photosStackView.isHidden = true
        for iv in photoImageViews {
            iv.image = nil
            iv.isHidden = true
        }
        reviewTextTopWithPhotosConstraint.isActive = false
        reviewTextTopWithoutPhotosConstraint.isActive = true

        showMoreButton.isHidden = true
        showMoreButtonTopConstraint.isActive = false

        createdLabelTopWithButtonConstraint.isActive = false
        createdLabelTopWithoutButtonConstraint.isActive = true
        reviewTextLabel.attributedText = nil
        usernameLabel.text = nil
        avatarImageView.image = nil
        ratingImageView.image = nil
        createdLabel.attributedText = nil
    }

    private func setupViews() {
        selectionStyle = .none

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingImageView.translatesAutoresizingMaskIntoConstraints = false
        reviewTextLabel.translatesAutoresizingMaskIntoConstraints = false
        showMoreButton.translatesAutoresizingMaskIntoConstraints = false
        createdLabel.translatesAutoresizingMaskIntoConstraints = false
        photosStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(ratingImageView)
        contentView.addSubview(reviewTextLabel)
        contentView.addSubview(showMoreButton)
        contentView.addSubview(createdLabel)
        contentView.addSubview(photosStackView)

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 18

        usernameLabel.font = .username
        reviewTextLabel.numberOfLines = 3
        reviewTextLabel.lineBreakMode = .byWordWrapping

        ratingImageView.contentMode = .scaleAspectFit
        showMoreButton.setAttributedTitle(ReviewCellConfig.showMoreText, for: .normal)
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.addTarget(self, action: #selector(showMoreTapped), for: .touchUpInside)

        createdLabel.font = .created
        createdLabel.textColor = .created
        
        photosStackView.axis = .horizontal
        photosStackView.spacing = 8
        photosStackView.distribution = .fillEqually
                
        for _ in 0..<maxPhotos {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 4
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 80).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 80).isActive = true
            iv.isHidden = true
            photosStackView.addArrangedSubview(iv)
            photoImageViews.append(iv)
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 9),
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            avatarImageView.widthAnchor.constraint(equalToConstant: 36),
            avatarImageView.heightAnchor.constraint(equalToConstant: 36),

            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            ratingImageView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 6),
            ratingImageView.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            ratingImageView.heightAnchor.constraint(equalToConstant: 16),
            ratingImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 100),

            photosStackView.leadingAnchor.constraint(equalTo: ratingImageView.leadingAnchor),
            photosStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -12),

            reviewTextLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            reviewTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            showMoreButton.leadingAnchor.constraint(equalTo: reviewTextLabel.leadingAnchor),

            createdLabel.leadingAnchor.constraint(equalTo: reviewTextLabel.leadingAnchor),
            createdLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            createdLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -9)
        ])

        photosStackView.topAnchor.constraint(equalTo: ratingImageView.bottomAnchor, constant: 8).isActive = true
        reviewTextTopWithPhotosConstraint = reviewTextLabel.topAnchor.constraint(equalTo: photosStackView.bottomAnchor, constant: 6)
        reviewTextTopWithoutPhotosConstraint = reviewTextLabel.topAnchor.constraint(equalTo: ratingImageView.bottomAnchor, constant: 14)
        reviewTextTopWithoutPhotosConstraint.isActive = true

        showMoreButtonTopConstraint = showMoreButton.topAnchor.constraint(equalTo: reviewTextLabel.bottomAnchor, constant: 6)
        createdLabelTopWithButtonConstraint = createdLabel.topAnchor.constraint(equalTo: showMoreButton.bottomAnchor, constant: 6)
        createdLabelTopWithoutButtonConstraint = createdLabel.topAnchor.constraint(equalTo: reviewTextLabel.bottomAnchor, constant: 6)

        NSLayoutConstraint.activate([
            showMoreButtonTopConstraint,
            createdLabelTopWithButtonConstraint
        ])
    }

    func updateShowMoreButtonVisibility(visible: Bool) {
        showMoreButton.isHidden = !visible

        if visible {
            showMoreButtonTopConstraint.isActive = true
            createdLabelTopWithButtonConstraint.isActive = true
            createdLabelTopWithoutButtonConstraint.isActive = false
        } else {
            showMoreButtonTopConstraint.isActive = false
            createdLabelTopWithButtonConstraint.isActive = false
            createdLabelTopWithoutButtonConstraint.isActive = true
        }
    }
    
    func updatePhotos(urls: [String]) {
        let hasPhotos = !urls.isEmpty
        
        photosStackView.isHidden = !hasPhotos
        
        reviewTextTopWithPhotosConstraint.isActive = false
        reviewTextTopWithoutPhotosConstraint.isActive = false
        
        if hasPhotos {
            reviewTextTopWithPhotosConstraint.isActive = true
        } else {
            reviewTextTopWithoutPhotosConstraint.isActive = true
        }
        
        for iv in photoImageViews {
            iv.image = nil
            iv.isHidden = true
        }
            
        for (i, url) in urls.prefix(maxPhotos).enumerated() {
            let iv = photoImageViews[i]
            iv.isHidden = false

            let uuid = ImageLoader.shared.loadImage(from: url) { [weak iv] image in
                iv?.image = image
            }

            if let uuid = uuid {
                imageLoadUUIDs.append(uuid)
            }
        }
    }

    @objc private func showMoreTapped() {
        guard let config = config else { return }
        config.onTapShowMore(config.id)
    }
}


// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
