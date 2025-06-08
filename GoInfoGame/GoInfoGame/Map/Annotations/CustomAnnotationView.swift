//
//  CustomAnnotationView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/06/25.
//

import MapKit

class CustomAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "CustomAnnotationView"
    
    private var checkmarkImageView: UIImageView?

    override func prepareForReuse() {
        super.prepareForReuse()
        removeCheckmark()
    }

    // Show or remove the checkmark based on selection
    func updateSelectionState(isSelected: Bool) {
        if isSelected {
            addCheckmark()
        } else {
            removeCheckmark()
        }
    }

    private func addCheckmark() {
        if checkmarkImageView == nil {
            let checkmarkImage = UIImage(systemName: "checkmark.circle.fill")?.withTintColor(.purple, renderingMode: .alwaysOriginal)
            let imageView = UIImageView(image: checkmarkImage)
            imageView.backgroundColor = .white
            imageView.layer.cornerRadius = (checkmarkImage?.size.width ?? 0.0) / 2.0
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: topAnchor, constant:0),
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 10),
                imageView.widthAnchor.constraint(equalToConstant: 24),
                imageView.heightAnchor.constraint(equalToConstant: 24)
            ])

            checkmarkImageView = imageView
        }
    }

    private func removeCheckmark() {
        checkmarkImageView?.removeFromSuperview()
        checkmarkImageView = nil
    }
}
