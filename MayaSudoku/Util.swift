import SpriteKit


func createGradientNode(size: CGSize, topColor: UIColor, bottomColor: UIColor) -> SKShapeNode{
    let gradientNode = SKShapeNode(rectOf: size, cornerRadius: 15)
    gradientNode.fillTexture = createGradientTexture(size: size, topColor: topColor, bottomColor: bottomColor)
    gradientNode.fillColor = .white
    gradientNode.position = CGPoint(x: size.width/2, y: size.height/2)
    return gradientNode
}

func createGradientTexture(size: CGSize, topColor: UIColor, bottomColor: UIColor) -> SKTexture {
    UIGraphicsBeginImageContext(size)
    guard let context = UIGraphicsGetCurrentContext() else {
        UIGraphicsEndImageContext()
        return SKTexture()
    }

    let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colorLocations: [CGFloat] = [0.0, 1.0]
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: colorLocations) else {
        UIGraphicsEndImageContext()
        return SKTexture()
    }

    let startPoint = CGPoint(x: 0, y: size.height)
    let endPoint = CGPoint(x: 0, y: 0)
    context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return SKTexture(image: image!)
}
