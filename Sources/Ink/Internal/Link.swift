/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

internal struct Link: Fragment {
    var modifierTarget: Modifier.Target { .links }

    var target: Target
    var text: FormattedText

    static func read(using reader: inout Reader) throws -> Link {
        try reader.read("[")
        let text: FormattedText
        var wikilink: FormattedText //? = nil
        if reader.currentCharacter == "[" {
            reader.advanceIndex()
            // Read up to a | or a ] for the link destination
            let wikilinkDestination = FormattedText.read(using: &reader, terminators: ["|", "]"])
            if reader.currentCharacter == "|" {
                reader.advanceIndex()
                // Link destination and label are different
                text = FormattedText.read(using: &reader, terminators: ["]"])
                wikilink = wikilinkDestination
            } else {
                // Link destination and label are the same
                text = wikilinkDestination
                wikilink = text
            }
            try reader.read("]]")
            return Link(target: .internalSite(wikilink.plainText()), text: text)
        } else {
            text = FormattedText.read(using: &reader, terminators: ["]"])
            try reader.read("]")
        }

        guard !reader.didReachEnd else { throw Reader.Error() }

        if reader.currentCharacter == "(" {
            reader.advanceIndex()
            let url = try reader.read(until: ")")
            return Link(target: .url(String(url)), text: text)
        } else {
            try reader.read("[")
            let reference = try reader.read(until: "]")
            return Link(target: .reference(reference), text: text)
        }
    }

    func html(usingURLs urls: NamedURLCollection,
              modifiers: ModifierCollection) -> String {
        let url = url(from: urls)
        let title = text.html(usingURLs: urls, modifiers: modifiers)
        guard !url.isEmpty else {
            // If a wikilink doesn't have a corresponding internal site page, mark it as missing but don't create a link.
            return "<span class=\"missing\">\(title)</span>"
        }
        return "<a href=\"\(url)\">\(title)</a>"
    }

    func plainText() -> String {
        text.plainText()
    }
}

extension Link {
    enum Target {
        case url(String)
        case reference(Substring)
        case internalSite(String)
    }
    
    func url(from urls: NamedURLCollection) -> String {
        switch target {
        case .url(let url):
            return urls.url(named: Substring(text.plainText())) ?? url
        case .reference(let name):
            return urls.url(named: name) ?? String(name)
        case .internalSite(let urlLabel):
            return urls.url(named: Substring(urlLabel)) ?? "" // ?? String(urlLabel)
        }
    }
}
