import Foundation

public func parseFasta(_ fileURL:URL) -> [RNA]  {
    var rnas = [RNA]()
    if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
        var sequence = ""
        let seqRegex = try! NSRegularExpression(pattern: "^[AUGCT]+$", options: [])
        var name:String? = nil
        for line in content.split(separator: "\n") {
            if line.starts(with: ">") {
                if sequence.count > 0 {
                    rnas.append(RNA(name:name,seq:sequence))
                    sequence = ""
                    name = nil
                }
                name = String(line.dropFirst())
            } else if !seqRegex.matches(in: String(line), options: [], range: NSRange(location: 0, length: line.count)).isEmpty {
                sequence += line
            }
        }
        if sequence.count > 0 {
            rnas.append(RNA(name:name,seq:sequence))
        }
    }
    return rnas
}

public func parseVienna(_ fileURL:URL) -> (RNA, String)?  {
    if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
        var sequence = ""
        var bn = ""
        let seqRegex = try! NSRegularExpression(pattern: "^[AUGCT]+$", options: [])
        for line in content.split(separator: "\n") {
            if line.starts(with: ">") {
                
            } else if !seqRegex.matches(in: String(line), options: [], range: NSRange(location: 0, length: line.count)).isEmpty {
                sequence += line
            } else {
                bn += line
            }
        }
        return (rna:RNA(seq:sequence), bn:bn)
    }
    return nil
}

public func parseCt(_ fileURL:URL) -> (RNA, [BasePair])?  {
    if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
        var sequence = ""
        var bps = [BasePair]()
        let seqRegex = try! NSRegularExpression(pattern: "^[:space:]+[0-9]+[:space:]+[AUGCaugc]", options: [])
        for line in content.split(separator: "\n") {
            if !seqRegex.matches(in: String(line), options: [], range: NSRange(location: 0, length: line.count)).isEmpty {
                let tokens = line.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces).filter({ $0 != ""})
                sequence += tokens[1]
                let pos1 = Int(tokens[0])
                let pos2 = Int(tokens[4])
                if let pos1 = pos1, let pos2 = pos2, pos1 >= pos2 && pos2 != 0, let location = Location(positions: [pos1, pos2]) {
                    bps.append(BasePair(location: location))
                }
            }
        }
        return (rna:RNA(seq:sequence), bps)
    }
    return nil
}

public func parseBpseq(_ fileURL:URL) -> (RNA, [BasePair])?  {
    if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
        var sequence = ""
        var bps = [BasePair]()
        for line in content.split(separator: "\n") {
            if line.starts(with: "#") {
                
            } else {
                let tokens = line.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces)
                sequence += tokens[1]
                let pos1 = Int(tokens[0])
                let pos2 = Int(tokens[2])
                if let pos1 = pos1, let pos2 = pos2, pos1 >= pos2 && pos2 != 0, let location = Location(positions: [pos1, pos2]) {
                    bps.append(BasePair(location: location))
                }
            }
        }
        return (RNA(seq:sequence), bps)
        
    }
    return nil
}
