public enum BinaryStreamErrors: Error {
	case EndOfStream
	case VarIntTooBig
	case VarLongTooBig
}

public class BinaryStream {
	public var buffer: [UInt8]
	public var offset: UInt
	private var bigEndian: Bool

	public static let UInt24Max: UInt32 = 0xffffff
	public static let Int24Max: Int32 = 0x7fffff

	public init(buffer: [UInt8] = [], offset: UInt = 0, bigEndian: Bool = true) {
		self.buffer = buffer
		self.offset = offset
		self.bigEndian = bigEndian
	}

	public func rewind() -> Void {
		self.offset = 0
	}

	public func reset() -> Void {
		self.buffer.removeAll()
		self.rewind()
	}

	public func eos() -> Bool {
		return self.offset >= self.buffer.count
	}

	public func swapEndian() -> Void {
		self.bigEndian = !self.bigEndian
	}

	public func isBigEndian() -> Bool {
		return self.bigEndian
	}

	public func isLittleEndian() -> Bool {
		return self.bigEndian == false
	}

	public func write(bytes: [UInt8]) -> Void {
		self.buffer.append(contentsOf: bytes)
	}

	public func read(size: UInt) throws -> [UInt8] {
		if self.eos() {
			throw BinaryStreamErrors.EndOfStream
		}

		self.offset += size
		return [UInt8](self.buffer[Int(self.offset - size)..<Int(self.offset)])
	}

	public func writeUInt8(value: UInt8) -> Void {
		self.write(bytes: [value])
	}

	public func writeBool(value: Bool) -> Void {
		self.writeUInt8(value: value == true ? 1 : 0)
	}

	public func writeInt8(value: Int8) -> Void {
		self.write(bytes: [UInt8(truncatingIfNeeded: value)])
	}

	public func writeUInt16(value: UInt16) -> Void {
		if self.bigEndian {
			self.write(bytes: [
				UInt8(truncatingIfNeeded: value >> 8),
				UInt8(truncatingIfNeeded: value),
			])
		} else {
			self.write(bytes: [
				UInt8(truncatingIfNeeded: value),
				UInt8(truncatingIfNeeded: value >> 8),
			])
		}
	}

	public func writeInt16(value: Int16) -> Void {
		self.writeUInt16(value: UInt16(truncatingIfNeeded: value))
	}

	private func _writeUInt24(value: UInt32) -> Void {
		if self.bigEndian {
			self.write(bytes: [
				UInt8(truncatingIfNeeded: value >> 16),
				UInt8(truncatingIfNeeded: value >> 8),
				UInt8(truncatingIfNeeded: value),
			])
		} else {
			self.write(bytes: [
				UInt8(truncatingIfNeeded: value),
				UInt8(truncatingIfNeeded: value >> 8),
				UInt8(truncatingIfNeeded: value >> 16),
			])
		}
	}

	public func writeUInt24(value: UInt32) -> Void {
		self._writeUInt24(value: UInt32(truncatingIfNeeded: value & BinaryStream.UInt24Max))
	}

	public func writeInt24(value: Int32) -> Void {
		self._writeUInt24(value: UInt32(truncatingIfNeeded: Int32(truncatingIfNeeded: value) & BinaryStream.Int24Max))
	}

	public func writeUInt32(value: UInt32) -> Void {
		if self.bigEndian {
			self.write(bytes: [
				UInt8(truncatingIfNeeded: value >> 24),
				UInt8(truncatingIfNeeded: value >> 16),
				UInt8(truncatingIfNeeded: value >> 8),
				UInt8(truncatingIfNeeded: value),
			])
		} else {
			self.write(bytes: [
				UInt8(truncatingIfNeeded: value),
				UInt8(truncatingIfNeeded: value >> 8),
				UInt8(truncatingIfNeeded: value >> 16),
				UInt8(truncatingIfNeeded: value >> 24),
			])
		}
	}

	public func writeInt32(value: Int32) -> Void {
		self.writeUInt32(value: UInt32(value))
	}

	public func writeUInt64(value: UInt64) -> Void {
		if self.bigEndian {
			self.write(bytes: [
				UInt8(truncatingIfNeeded: value >> 56),
				UInt8(truncatingIfNeeded: value >> 48),
				UInt8(truncatingIfNeeded: value >> 40),
				UInt8(truncatingIfNeeded: value >> 32),
				UInt8(truncatingIfNeeded: value >> 24),
				UInt8(truncatingIfNeeded: value >> 16),
				UInt8(truncatingIfNeeded: value >> 8),
				UInt8(truncatingIfNeeded: value),
			])
		} else {
			self.write(bytes: [
				UInt8(truncatingIfNeeded: value),
				UInt8(truncatingIfNeeded: value >> 8),
				UInt8(truncatingIfNeeded: value >> 16),
				UInt8(truncatingIfNeeded: value >> 24),
				UInt8(truncatingIfNeeded: value >> 32),
				UInt8(truncatingIfNeeded: value >> 40),
				UInt8(truncatingIfNeeded: value >> 48),
				UInt8(truncatingIfNeeded: value >> 56),
			])
		}
	}

	public func writeInt64(value: Int64) -> Void {
		self.writeUInt64(value: UInt64(truncatingIfNeeded: value))
	}

	public func writeVarInt(value: UInt32) -> Void {
		var editableValue: UInt32 = value
		for _ in 0..<5 {
			let toWrite: UInt8 = UInt8(editableValue & 0x7f)

			editableValue >>= 7

			if editableValue != 0 {
				self.writeUInt8(value: toWrite | 0x80)
			} else {
				self.writeUInt8(value: toWrite)
				break
			}
		}
	}

	public func writeVarInt64(value: UInt64) -> Void {
		var editableValue: UInt64 = value
		for _ in 0..<10 {
			let toWrite: UInt8 = UInt8(editableValue & 0x7f)

			editableValue >>= 7

			if editableValue != 0 {
				self.writeUInt8(value: toWrite | 0x80)
			} else {
				self.writeUInt8(value: toWrite)
				break
			}
		}
	}

	public func writeZigZag32(value: Int32) -> Void {
		self.writeVarInt(value: UInt32((value << 1) ^ (value >> 31)))
	}

	public func writeZigZag64(value: Int64) -> Void {
		self.writeVarInt64(value: UInt64((value << 1) ^ (value >> 63)))
	}

	public func writeFloat(value: Float) -> Void {
		self.writeUInt32(value: value.bitPattern)
	}

	public func writeDouble(value: Double) -> Void {
		self.writeUInt64(value: value.bitPattern)
	}

	public func padWithZeroToSize(size: UInt) -> Void {
    		let buffer: [UInt8] = [UInt8](repeating: 0, count: Int(truncatingIfNeeded: size))
    		self.write(bytes: buffer)
	}

	public func readUInt8() throws -> UInt8 {
		return try! self.read(size: 1)[0]
	}

	public func readBool() throws -> Bool {
		return try! self.readUInt8() == 1 ? true : false
	}

	public func readInt8() -> Int8 {
		return Int8(truncatingIfNeeded: try! self.readUInt8())
	}

	public func readUInt16() throws -> UInt16 {
		let bytes: [UInt8] = try! self.read(size: 2)
		var result: UInt16 = 0
		if self.bigEndian {
			result |= UInt16(truncatingIfNeeded: bytes[0]) << 8
			result |= UInt16(truncatingIfNeeded: bytes[1])
		} else {
			result |= UInt16(truncatingIfNeeded: bytes[0])
			result |= UInt16(truncatingIfNeeded: bytes[1]) << 8
		}
		return result
	}

	public func readInt16() throws -> Int16 {
		return Int16(truncatingIfNeeded: try! self.readUInt16())
	}

	private func _readUInt24() throws -> UInt32 {
		let bytes: [UInt8] = try! self.read(size: 3)
		var result: UInt32 = 0
		if self.bigEndian {
			result |= UInt32(truncatingIfNeeded: bytes[0]) << 16
			result |= UInt32(truncatingIfNeeded: bytes[1]) << 8
			result |= UInt32(truncatingIfNeeded: bytes[2])
		} else {
			result |= UInt32(truncatingIfNeeded: bytes[0])
			result |= UInt32(truncatingIfNeeded: bytes[1]) << 8
			result |= UInt32(truncatingIfNeeded: bytes[2]) << 16
		}
		return result
	}

	public func readUInt24() throws -> UInt32 {
		return UInt32((try! self._readUInt24()) & BinaryStream.UInt24Max)
	}

	public func readInt24() throws -> Int32 {
		return Int32(truncatingIfNeeded: Int32(truncatingIfNeeded: try! self._readUInt24()) & BinaryStream.Int24Max)
	}

	public func readUInt32() throws -> UInt32 {
		let bytes: [UInt8] = try! self.read(size: 4)
		var result: UInt32 = 0
		if self.bigEndian {
			result |= UInt32(truncatingIfNeeded: bytes[0]) << 24
			result |= UInt32(truncatingIfNeeded: bytes[1]) << 16
			result |= UInt32(truncatingIfNeeded: bytes[2]) << 8
			result |= UInt32(truncatingIfNeeded: bytes[3])
		} else {
			result |= UInt32(truncatingIfNeeded: bytes[0])
			result |= UInt32(truncatingIfNeeded: bytes[1]) << 8
			result |= UInt32(truncatingIfNeeded: bytes[2]) << 16
			result |= UInt32(truncatingIfNeeded: bytes[3]) << 24
		}
		return result
	}

	public func readInt32() throws -> Int32 {
		return Int32(truncatingIfNeeded: try! self.readUInt32())
	}

	public func readUInt64() throws -> UInt64 {
		let bytes: [UInt8] = try! self.read(size: 8)
		var result: UInt64 = 0
		if self.bigEndian {
			result |= UInt64(truncatingIfNeeded: bytes[0]) << 56
			result |= UInt64(truncatingIfNeeded: bytes[1]) << 48
			result |= UInt64(truncatingIfNeeded: bytes[2]) << 40
			result |= UInt64(truncatingIfNeeded: bytes[3]) << 32
			result |= UInt64(truncatingIfNeeded: bytes[4]) << 24
			result |= UInt64(truncatingIfNeeded: bytes[5]) << 16
			result |= UInt64(truncatingIfNeeded: bytes[6]) << 8
			result |= UInt64(truncatingIfNeeded: bytes[7])
		} else {
			result |= UInt64(truncatingIfNeeded: bytes[0])
			result |= UInt64(truncatingIfNeeded: bytes[1]) << 8
			result |= UInt64(truncatingIfNeeded: bytes[2]) << 16
			result |= UInt64(truncatingIfNeeded: bytes[3]) << 24
			result |= UInt64(truncatingIfNeeded: bytes[4]) << 32
			result |= UInt64(truncatingIfNeeded: bytes[5]) << 40
			result |= UInt64(truncatingIfNeeded: bytes[6]) << 48
			result |= UInt64(truncatingIfNeeded: bytes[7]) << 56
		}
		return result
	}

	public func readInt64() throws -> Int64 {
		return Int64(truncatingIfNeeded: try! self.readUInt64())
	}
	
	public func readVarInt() throws -> UInt32 {
		var result: UInt32 = 0
		var index: UInt = 0
		while index < 35 {
			let toRead: UInt32 = UInt32(try! self.readUInt8())

			result |= (toRead & 0x7f) << index

			if (toRead & 0x80) == 0 {
				return result
			}

			index += 7
		}
		throw BinaryStreamErrors.VarIntTooBig
	}

	public func readVarInt64() throws -> UInt64 {
		var result: UInt64 = 0
		var index: UInt = 0
		while index < 70 {
			let toRead: UInt64 = UInt64(try! self.readUInt8())

			result |= (toRead & 0x7f) << index

			if (toRead & 0x80) == 0 {
				return result
			}

			index += 7
		}
		throw BinaryStreamErrors.VarLongTooBig
	}

	public func readZigZag32() throws -> Int32 {
		let result: UInt32 = try! self.readVarInt()
		return Int32((Int32(result) >> 1) ^ -(Int32(result) & 1))
	}

	public func readZigZag64() throws -> Int64 {
		let result: UInt64 = try! self.readVarInt64()
		return Int64((Int64(result) >> 1) ^ -(Int64(result) & 1))
	}

	public func readFloat() throws -> Float {
		let result = try! self.readUInt32()
		return Float(bitPattern: result)
	}

	public func readDouble() throws -> Double {
		let result: UInt64 = try! self.readUInt64()
		return Double(bitPattern: result)
	}

	public func readRemaining() throws -> [UInt8] {
		return try! self.read(size: UInt(self.buffer.count) - self.offset)
	}

	deinit {
		self.reset()
	}
}
