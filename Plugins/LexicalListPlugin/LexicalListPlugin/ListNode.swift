/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import Lexical

public enum ListType: String, Codable {
  case bullet = "bullet"
  case number = "number"
  case check = "check"
}

extension NodeType {
  public static let list = NodeType(rawValue: "list")
}

public class ListNode: ElementNode {
    enum CodingKeys: String, CodingKey {
      case listType
      case start
    }
    
  private var listType: ListType = .bullet
  private var start: Int = 1

  public required convenience init(listType: ListType, start: Int, key: NodeKey? = nil) {
    self.init(key)
    self.listType = listType
    self.start = start
  }

  override public init() {
    super.init()
  }

  override public init(_ key: NodeKey?) {
    super.init(key)
  }

    public required init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.listType = try container.decodeIfPresent(ListType.self, forKey: .listType) ?? .bullet
      self.start = try container.decodeIfPresent(Int.self, forKey: .start) ?? 1
      try super.init(from: decoder)
    }
    
    override public func encode(to encoder: Encoder) throws {
      try super.encode(to: encoder)
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(self.listType, forKey: .listType)
      try container.encode(self.start, forKey: .start)
    }
    
  override public class func getType() -> NodeType {
    return .list
  }

  // MARK: getters/setters

  public func getListType() -> ListType {
    return getLatest().listType
  }

  @discardableResult
  public func setListType(_ type: ListType) throws -> ListNode {
    let node: ListNode = try getWritable()
    node.listType = type
    return node
  }

  public func getStart() -> Int {
    return getLatest().start
  }

  @discardableResult
  public func setStart(_ start: Int) throws -> ListNode {
    let node: ListNode = try getWritable()
    node.start = start
    return node
  }

  override public func clone() -> Self {
    Self(listType: listType, start: start, key: key)
  }
}
