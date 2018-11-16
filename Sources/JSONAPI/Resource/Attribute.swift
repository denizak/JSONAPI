//
//  Attribute.swift
//  JSONAPI
//
//  Created by Mathew Polzin on 11/13/18.
//

public struct TransformAttribute<RawValue: Codable, Transformer: JSONAPI.Transformer>: Codable where Transformer.From == RawValue {
	private let rawValue: RawValue
	
	public let value: Transformer.To
	
	public init(rawValue: RawValue) throws {
		self.rawValue = rawValue
		value = try Transformer.transform(rawValue)
	}
}

public typealias Attribute<T: Codable> = TransformAttribute<T, IdentityTransformer<T>>

extension TransformAttribute: Equatable where Transformer.From: Equatable, Transformer.To: Equatable {}

// MARK: - Codable
extension TransformAttribute {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		let rawVal: RawValue
		
		// A little trickery follows. If the value is nil, the
		// container.decode(Value.self) will fail even if Value
		// is Optional. However, we can check if decoding nil
		// succeeds and then attempt to coerce nil to a Value
		// type at which point we can store nil in `value`.
		let anyNil: Any? = nil
		if container.decodeNil(),
			let val = anyNil as? Transformer.From {
				rawVal = val
		} else {
			rawVal = try container.decode(Transformer.From.self)
		}
		
		rawValue = rawVal
		value = try Transformer.transform(rawVal)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		
		// See note in decode above about the weirdness
		// going on here.
		let anyNil: Any? = nil
		if let _ = anyNil as? Transformer.From,
			(rawValue as Any?) == nil {
			try container.encodeNil()
		}
		
		try container.encode(rawValue)
	}
}

// MARK: - Transformers

public protocol Transformer {
	associatedtype From
	associatedtype To
	
	static func transform(_ from: From) throws -> To
}

public enum IdentityTransformer<T>: Transformer {
	public static func transform(_ from: T) throws -> T { return from }
}