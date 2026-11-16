import Foundation

struct Account: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    // SFSymbol
    var imageName: String
    var rgbColor: String
    
    init(name: String,
         imageName: String,
         rgbColor: String) {
        self.name = name
        self.imageName = imageName
        self.rgbColor = rgbColor
        self.id = IdHelper.accountId(name: name)
    }
    
    init(id: UUID,
         name: String,
         imageName: String,
         rgbColor: String) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.rgbColor = rgbColor
    }


}

