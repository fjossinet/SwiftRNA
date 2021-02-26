import Foundation

public class Block: CustomStringConvertible {
    public var start:Int
    public var end:Int
    public var length:Int {
        get {
            return self.end - self.start + 1
        }
    }
    public var positions:[Int] {
        get {
            return Array(self.start...self.end)
        }
    }
    
    public var description: String {
        "\(start)-\(end)"
    }
    
    public init(start:Int, end:Int) {
        self.start = start < end ? start : end
        self.end = start > end ? start : end
    }
    
    public func contains(_ position:Int) -> Bool {
        position >= start && position <= end
    }
    
    public static func + (lhs: Block, rhs: [Int]) -> Location {
        var positions = lhs.positions
        positions.append(contentsOf: rhs)
        return Location(positions: positions)!
    }
    
    public static func - (lhs: Block, rhs: [Int]) -> Location {
        let diff  = lhs.positions.filter { !rhs.contains($0) }
        return Location(positions:diff)!
    }
    
}

public class Location: CustomStringConvertible, Equatable {
    
    public static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.start == rhs.start && lhs.end == rhs.end && lhs.length == rhs.length
    }
    
    public var blocks:[Block]
    
    public var positions:[Int] {
        get {
            var pos = [Int]()
            for b in self.blocks {
                pos += b.positions
            }
            return pos
        }
    }
    
    public var start:Int {
        get {
            return self.blocks.first!.start
        }
    }
    
    public var end:Int {
        get {
            return self.blocks.last!.end
        }
    }
    
    public var length:Int {
        get {
            return self.blocks.reduce(0,{ result, block in
                result + block.length
            })
        }
    }
    
    public var description: String {
        String((self.blocks.map {$0.description+","}).joined().dropLast())
    }
    
    public init(start: Int, end:Int) {
        self.blocks = [start < end ? Block(start:start, end:end) : Block(start:end, end:start)]
    }
    
    public init?(fromDescr descr:String) {
        self.blocks = [Block]()
        for interval in descr.split(separator: ",") {
            
            let ends = interval.split(separator: "-").map {Int($0)}
            guard let start = ends.first!, let end = ends.last! else {
                return nil
            }
            
            start < end ? self.blocks.append(Block(start: start,end: end)) : self.blocks.append(Block(start: end,end: start))
        }
    }
    
    public init?(positions:[Int]) {
        guard let blocks = toBlocks(positions: positions) else {
            return nil
        }
        self.blocks = blocks
    }
    
    public func addPosition(_ pos:Int) {
        var positions = self.positions
        if !positions.contains(pos) {
            positions.append(pos)
            self.blocks.removeAll()
            self.blocks = toBlocks(positions: positions)!
        }
    }
    
    public func contains(_ position:Int) -> Bool {
        for block in self.blocks {
            if block.contains(position) {
                return true
            }
        }
        return false
    }
    
    public static func + (lhs: Location, rhs: [Int]) -> Location {
        var positions = lhs.positions
        positions.append(contentsOf: rhs)
        return Location(positions: positions)!
    }
    
    public static func - (lhs: Location, rhs: [Int]) -> Location {
        let diff  = lhs.positions.filter { !rhs.contains($0) }
        return Location(positions:diff)!
    }
    
}

public class RNA {
    
    public static func ~= (lhs: RNA, rhs: String) -> [Block] {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return [] }
        let results = regex.matches(in: lhs.seq,
                                    range: NSRange(lhs.seq.startIndex..., in: lhs.seq))
        return results.map {
            Block(start: $0.range.location+1, end: $0.range.location+1 + $0.range.length-1)
        }
    }
    
    public static func + (lhs: RNA, rhs: RNA) -> RNA {
        RNA(seq:lhs.seq + rhs.seq)
    }
    
    public static func / (lhs: RNA, rhs: [Block]) -> [RNA] {
        var rnas = [RNA]()
        for b in rhs {
            let start = lhs.seq.index(lhs.seq.startIndex, offsetBy: b.start-1)
            let end = lhs.seq.index(lhs.seq.startIndex, offsetBy: b.end-1)
            rnas.append(RNA(seq:String(lhs.seq[start...end])))
        }
        return rnas
    }
    
    public var name:String?
    public var seq:String
    public var length:Int {
        get {
            self.seq.count
        }
    }
    
    public init(name:String?=nil, seq:String) {
        self.name = name
        self.seq = seq
    }
    
}

public class BasePair: Hashable,CustomStringConvertible {
    public var location:Location
    public var edge5:Edge
    public var edge3:Edge
    public var orientation:Orientation
    public var description: String {
        "\(location) \(orientation):\(edge5):\(edge3)"
    }
    
    public init(location:Location, edge5:Edge = .WC, edge3:Edge = .WC, orientation:Orientation = .cis) {
        self.location = location
        self.edge5 = edge5
        self.edge3 = edge3
        self.orientation = orientation
    }
    
    public static func == (lhs: BasePair, rhs: BasePair) -> Bool {
        lhs.location.start == rhs.location.start && lhs.location.end == rhs.location.end && lhs.edge5 == rhs.edge5 && lhs.edge3 == rhs.edge3 && lhs.orientation == rhs.orientation
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(location.start)
        hasher.combine(location.end)
        hasher.combine(edge5)
        hasher.combine(edge3)
        hasher.combine(orientation)
    }
    
}

public class SingleStrand:Equatable {
    
    public static func == (lhs: SingleStrand, rhs: SingleStrand) -> Bool {
        lhs.location == rhs.location
    }
    
    public var name:String
    public var location:Location
    public var length:Int {
        get {
            self.location.length
        }
    }
    
    public init(name:String = "MySingleStrand", start:Int, end:Int) {
        self.name = name
        self.location = Location(start: start, end: end)
    }

    
}

public class Helix: Equatable {
    
    public static func == (lhs: Helix, rhs: Helix) -> Bool {
        lhs.location == rhs.location
    }
    
    public var name:String
    public var secondaryInteractions = Set<BasePair>()
    public var junctionsLinked:(Junction?,Junction?) = (nil,nil)
    public var location:Location {
        get {
            let positionsInHelix = Array(self.secondaryInteractions.map({(bp:BasePair) -> [Int] in
                return [bp.location.start,bp.location.end ]
            }).joined())
            return Location(positions: positionsInHelix)!
        }
    }
    
    public var length:Int {
        get {
            return self.location.length/2
        }
    }
    
    public var ends:[Int] {
        get {
            var ends = [Int]()
            for b in self.location.blocks {
                ends.append(contentsOf: [b.start,b.end])
            }
            return ends.sorted()
        }
    }
    
    public init(name:String = "MyHelix") {
        self.name = name
    }
    
    public func setJunction(_ junction:Junction) {
        if let _ = self.junctionsLinked.0 {
            self.junctionsLinked.1 = junction
        } else {
            self.junctionsLinked.0 = junction
        }
    }
    
    public func getPairedPosition(position:Int) -> Int? {
        for bp in self.secondaryInteractions {
            if bp.location.start == position {
                return bp.location.end
            }
            if bp.location.end == position {
                return bp.location.start
            }
        }
        return nil
    }
    
}

public class Junction {
    public var name:String
    public var location:Location
    public var helicesLinked:[Helix]
    
    public var length:Int {
        get {
            self.location.length
        }
    }
    
    public var type:JunctionType {
        get {
            JunctionType(rawValue: self.location.blocks.count)!
        }
    }
    
    public init(name:String = "MyJunction", location:Location, helicesLinked:[Helix]) {
        self.name = name
        self.location = location
        self.helicesLinked = helicesLinked
        for h in self.helicesLinked {
            h.setJunction(self)
        }
    }
    
}

public class SecondaryStructure {
    public var name:String?
    public var source:String?
    public var tertiaryInteractions = Set<BasePair>()
    public var secondaryInteractions:[BasePair] {
        get {
            var interactions = [BasePair]()
            for h in self.helices {
                interactions.append(contentsOf: h.secondaryInteractions)
            }
            return interactions
        }
    }
    public var helices = [Helix]()
    public var junctions = [Junction]()
    public var length:Int {
        get {
            self.rna.seq.count
        }
    }
    public var rna:RNA
    
    public var bn:String {
        get {
            var bn = ""
            for i in 1...self.length {
                for h in self.helices {
                    if i >= h.ends[0] && i <= h.ends[1] {
                        bn += "("
                        break
                    } else if i >= h.ends[2] && i <= h.ends[3] {
                        bn += ")"
                        break
                    }
                }
                if bn.count != i {
                    bn += "."
                }
            }
            return bn
        }
    }
    
    public init(rna:RNA, name:String? = nil, source:String? = nil, bracketNotation bn:String? = nil , basePairs bps:[BasePair]? = nil) {
        self.name = name
        self.source = source
        self.rna = rna
        var basePairs: [BasePair]! = nil
        
        if let bps = bps {
            basePairs = bps
        }
        
        if let bn = bn {
            basePairs = toBasePairs(bracketNotation:bn)
        }
        
        if !basePairs.isEmpty {
            basePairs.sort(by: {(bp0:BasePair, bp1:BasePair) -> Bool in
                return bp0.location.start < bp1.location.start
            })
            var bpInHelix = Set<BasePair>()
            BASEPAIRS:
                for i in 0..<basePairs.count-1 {
                    let start1 = basePairs[i].location.start
                    let end1 = basePairs[i].location.end
                    let start2 = basePairs[i+1].location.start
                    let end2 = basePairs[i+1].location.end
                    
                    for storedH in self.helices { //if the position processed is already in a secondary interaction
                        if storedH.location.contains(start1) || storedH.location.contains(end1) {
                            continue BASEPAIRS
                        }
                    }
                    
                    if start1+1 == start2 && end1-1 == end2 {
                        bpInHelix.insert(basePairs[i])
                        bpInHelix.insert(basePairs[i+1])
                    } else {
                        if !bpInHelix.isEmpty {
                            let h = Helix()
                            for bp in bpInHelix {
                                h.secondaryInteractions.insert(bp)
                            }
                            self.helices.append(h)
                            bpInHelix.removeAll()
                        }
                    }
            }
            //last helix
            if !bpInHelix.isEmpty {
                let h = Helix()
                for bp in bpInHelix {
                    h.secondaryInteractions.insert(bp)
                }
                self.helices.append(h)
                bpInHelix.removeAll()
            }
            
            var pknots = [Helix]()
            if self.helices.count >= 2 {
                for i in 0..<self.helices.count-1 {
                    for j in i+1..<self.helices.count {
                        if self.helices[i].location.start > self.helices[j].location.start && self.helices[i].location.start < self.helices[j].location.end && self.helices[i].location.end > self.helices[j].location.end || self.helices[j].location.start > self.helices[i].location.start && self.helices[j].location.start < self.helices[i].location.end && self.helices[j].location.end > self.helices[i].location.end {
                            pknots.append(self.helices[i].length > self.helices[j].length ? self.helices[j] : self.helices[i])
                        }
                    }
                }
            }
            
            for pknot in pknots {
                self.helices.removeAll(where:{$0 == pknot})
            }
            
            //now the tertiary interactions
            let secondaryInteractions = self.secondaryInteractions
            basePairs.removeAll(where: {secondaryInteractions.contains($0)})
            for bp in basePairs {
                self.tertiaryInteractions.insert(bp)
            }
            //now the junctions
            self.findJunctions()
        }
        
    }
    
    /**
     Return the position paired to the position given as argument. Return nil if this position is not paired at all.
     **/
    public func getPairedPosition(position:Int) -> Int? {
        for h in self.helices {
            for bp in h.secondaryInteractions {
                if bp.location.start == position {
                    return bp.location.end
                }
                if bp.location.end == position {
                    return bp.location.start
                }
            }
        }
        for bp in tertiaryInteractions {
            if bp.location.start == position {
                return bp.location.end
            }
            if bp.location.end == position {
                return bp.location.start
            }
        }
        return nil
    }
    
    /**
     Return the next end of an helix (its paired position and the helix itself) after the position given as argument (along the sequence).
     Useful to get the next helix after an helix.
     **/
    public func getNextHelixEnd(position:Int) -> (Int,Int, Helix)? {
        var minNextEnd = length //the next end is the lowest 3' position of an helix right after the position given as argument
        var pairedPosition:Int!
        var helix:Helix!
        for h in self.helices {
            if h.ends[0] > position && h.ends[0] < minNextEnd {
                minNextEnd = h.ends[0]
                pairedPosition = h.ends[3]
                helix = h
            }
            if h.ends[2] > position && h.ends[2] < minNextEnd {
                minNextEnd = h.ends[2]
                pairedPosition = h.ends[1]
                helix = h
            }
        }
        return minNextEnd == length ? nil : (minNextEnd, pairedPosition, helix)
    }
    
    public func findJunctions() {
        self.junctions.removeAll()
        for h in self.helices {
            h.junctionsLinked = (nil,nil)
        }
        var positionsInJunction = [Int]()
        var helicesLinked = [Helix]()
        for h in self.helices {
            positionsInJunction.removeAll()
            //one side of the helix
            var pos = h.ends[1] //3'-end
            if self.junctions.filter({$0.location.contains(pos)}).isEmpty { //already in a junction?
                repeat {
                    if let (nextEnd, pairedPosition, helix) = self.getNextHelixEnd(position: pos) {
                        positionsInJunction.append(contentsOf: pos...nextEnd)
                        helicesLinked.append(helix)
                        pos = pairedPosition
                    } else { //not a junction
                        positionsInJunction.removeAll()
                        helicesLinked.removeAll()
                        break
                    }
                } while (pos != h.ends[1])
                
                if let location = Location(positions: positionsInJunction) {
                    self.junctions.append(Junction(location: location, helicesLinked: helicesLinked))
                }
            }
            
            //the other side (of the river ;-) )
            positionsInJunction.removeAll()
            helicesLinked.removeAll()
            pos = h.ends[3] //3'-end
            if self.junctions.filter({$0.location.contains(pos)}).isEmpty { //already in a junction?
                repeat {
                    if let (nextEnd, pairedPosition, helix) = self.getNextHelixEnd(position: pos) {
                        positionsInJunction.append(contentsOf: pos...nextEnd)
                        helicesLinked.append(helix)
                        pos = pairedPosition
                    } else { //not a junction
                        positionsInJunction.removeAll()
                        helicesLinked.removeAll()
                        break
                    }
                } while (pos != h.ends[3])
                
                if let location = Location(positions: positionsInJunction) {
                    self.junctions.append(Junction(location: location, helicesLinked: helicesLinked))
                }
            }
        }
    }
}

public enum Edge {
    case WC, Hoogsteen, Sugar, Unknown
}

public enum Orientation {
    case cis, trans, Unknown
}

public enum JunctionType:Int {
    case ApicalLoop = 1, InnerLoop, ThreeWay, FourWay, FiveWay, SixWay, SevenWay, EightWay, NineWay, TenWay, ElevenWay, TwelveWay, ThirteenWay, FourteenWay, FiveteenWay, SixteenWay, Flower
}

func toBlocks(positions:[Int]) -> [Block]? {
    var blocks = [Block]()
    let _positions = positions.sorted()
    guard var start = _positions.first else {
        return nil
    }
    var length = 0
    var i = 0
    
    while i < _positions.count-1 {
        if _positions[i]+1 == _positions[i+1] {
            length += 1
        }
        else {
            blocks.append(Block(start: start, end: start+length))
            length = 0
            start = _positions[i+1]
        }
        i += 1
    }
    blocks.append(Block(start: start, end: start+length))
    return blocks
}

func toBasePairs(bracketNotation bn:String) -> [BasePair] {
    var bps = [BasePair]()
    var lastLeft = [Edge](), lastPos = [Int](), pos=0
    for c in bn {
        pos += 1
        switch c {
        case "(": lastLeft.append(.WC) ; lastPos.append(pos)
        case "{": lastLeft.append(.Sugar) ; lastPos.append(pos)
        case "[": lastLeft.append(.Hoogsteen) ; lastPos.append(pos)
        case ")":
            if let lastPos = lastPos.popLast(), let location = Location(positions: [lastPos,pos]), let lastLeft = lastLeft.popLast() {
                bps.append(BasePair(location: location, edge5: lastLeft, edge3: .WC))
            }
        case "}":
            if let lastPos = lastPos.popLast(), let location = Location(positions: [lastPos,pos]), let lastLeft = lastLeft.popLast() {
                bps.append(BasePair(location: location, edge5: lastLeft, edge3: .Sugar))
            }
        case "]":
            if let lastPos = lastPos.popLast(), let location = Location(positions: [lastPos,pos]), let lastLeft = lastLeft.popLast() {
                bps.append(BasePair(location: location, edge5: lastLeft, edge3: .Hoogsteen))
            }
        default: continue
        }
    }
    return bps
}
