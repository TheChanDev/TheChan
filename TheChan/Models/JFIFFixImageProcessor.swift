import Foundation
import Kingfisher

class JFIFFixImageProcessor: ImageProcessor {
    let identifier = "io.acedened.jfiffiximageprocessor"

    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            let newData = fixHeader(in: data)
            return DefaultImageProcessor().process(item: .data(newData), options: options)
        }
    }

    func fixHeader(in data: Data) -> Data {
        guard data.count > 18 else { return data }
        let checkValue: UInt8 = data[5]

        if checkValue != 14 {
            return data
        }

        var data = data
        data.insert(0, at: 16)
        data.insert(0, at: 17)
        data[5] = 16

        return data
    }
}
