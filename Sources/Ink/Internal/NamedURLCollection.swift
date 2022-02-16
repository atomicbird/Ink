/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

internal struct NamedURLCollection {
    private let urlsByName: [String : String]

    init(urlsByName: [String : String]) {
        self.urlsByName = urlsByName
    }

    func url(named name: Substring) -> String? {
        urlsByName[name.lowercased()]
    }
}
