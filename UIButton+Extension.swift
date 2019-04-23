extension UIButton {
    func centerImageAndText(space:CGFloat) {
        guard let text:NSString = self.titleLabel?.text as NSString? else {
            return
        }
        
        var textSize = text.size(withAttributes: [
            NSAttributedString.Key.font: (titleLabel?.font)!
            ])
        textSize.width = CGFloat(ceilf(Float(textSize.width)))
        textSize.height = CGFloat(ceilf(Float(textSize.height)))
        
        let totalHeight:CGFloat = (imageView?.size.height ?? 0) + (titleLabel?.height ?? 0) + space
        imageEdgeInsets = UIEdgeInsets(top: (totalHeight - (imageView?.height ?? 0)) * -1, left: 0, bottom: 0, right: (titleLabel?.width ?? 0) * -1)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: (imageView?.width ?? 0) * -1, bottom: -1 * (totalHeight - (titleLabel?.height ?? 0)), right: 0)
    }
}
