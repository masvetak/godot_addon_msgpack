extends Node

const MSGPACK_FORMAT_POSITIVE_FIXINT = 0x00
const MSGPACK_FORMAT_FIXMAP = 0x80
const MSGPACK_FORMAT_FIXARRAY = 0x90
const MSGPACK_FORMAT_FIXSTR = 0xA0
const MSGPACK_FORMAT_NIL = 0xC0
const MSGPACK_FORMAT_NEVER_USED = 0xC1
const MSGPACK_FORMAT_FALSE = 0xC2
const MSGPACK_FORMAT_TRUE = 0xC3
const MSGPACK_FORMAT_BIN_8 = 0xC4
const MSGPACK_FORMAT_BIN_16 = 0xC5
const MSGPACK_FORMAT_BIN_32 = 0xC6
const MSGPACK_FORMAT_EXT_8 = 0xC7
const MSGPACK_FORMAT_EXT_16 = 0xC8
const MSGPACK_FORMAT_EXT_32 = 0xC9
const MSGPACK_FORMAT_FLOAT_32 = 0xCA
const MSGPACK_FORMAT_FLOAT_64 = 0xCB
const MSGPACK_FORMAT_UINT_8 = 0xCC
const MSGPACK_FORMAT_UINT_16 = 0xCD
const MSGPACK_FORMAT_UINT_32 = 0xCE
const MSGPACK_FORMAT_UINT_64 = 0xCF
const MSGPACK_FORMAT_INT_8 = 0xD0
const MSGPACK_FORMAT_INT_16 = 0xD1
const MSGPACK_FORMAT_INT_32 = 0xD2
const MSGPACK_FORMAT_INT_64 = 0xD3
const MSGPACK_FORMAT_FIXEXT_1 = 0xD4
const MSGPACK_FORMAT_FIXEXT_2 = 0xD5
const MSGPACK_FORMAT_FIXEXT_4 = 0xD6
const MSGPACK_FORMAT_FIXEXT_8 = 0xD7
const MSGPACK_FORMAT_FIXEXT_16 = 0xD8
const MSGPACK_FORMAT_STR_8 = 0xD9
const MSGPACK_FORMAT_STR_16 = 0xDA
const MSGPACK_FORMAT_STR_32 = 0xDB
const MSGPACK_FORMAT_ARRAY_16 = 0xDC
const MSGPACK_FORMAT_ARRAY_32 = 0xDD
const MSGPACK_FORMAT_MAP_16 = 0xDE
const MSGPACK_FORMAT_MAP_32 = 0xDF
const MSGPACK_FORMAT_NEGATIVE_FIXINT = 0xE0

# ------------------------------------------------------------------------------
# Public methods
# ------------------------------------------------------------------------------

func pack(data):
	var buffer = StreamPeerBuffer.new()
	buffer.big_endian = true
	
	var error: Dictionary = {
		'error' = OK, 
		'error_string' = ""
	}
	
	_pack(data, buffer, error)
	var result: PackedByteArray = buffer.data_array
	
	if error['error'] == OK:
		return result
	else:
		print("[Msgpack] error: ", error['error_string'])
		return null

func unpack(data: PackedByteArray):
	var buffer = StreamPeerBuffer.new()
	buffer.big_endian = true
	buffer.data_array = data
	
	var error: Dictionary = {
		'error' = OK, 
		'error_string' = ""
	}
	
	var result = _unpack(buffer, error)
	
	if error['error'] == OK:
		return result
	else:
		print("[Msgpack] error: ", error['error_string'])
		return null

# ------------------------------------------------------------------------------
# Private methods
# ------------------------------------------------------------------------------

func _pack(data, buffer: StreamPeerBuffer, error: Dictionary):
	match typeof(data):
		TYPE_NIL:
			buffer.put_u8(MSGPACK_FORMAT_NIL)
		
		TYPE_BOOL:
			if data:
				buffer.put_u8(MSGPACK_FORMAT_TRUE)
			else:
				buffer.put_u8(MSGPACK_FORMAT_FALSE)
		
		TYPE_INT:
			if -(1 << 5) <= data and data <= (1 << 7) - 1:
				buffer.put_8(data)
			elif -(1 << 7) <= data and data <= (1 << 7):
				buffer.put_u8(MSGPACK_FORMAT_INT_8)
				buffer.put_8(data)
			elif -(1 << 15) <= data and data <= (1 << 15):
				buffer.put_u8(MSGPACK_FORMAT_INT_16)
				buffer.put_16(data)
			elif -(1 << 31) <= data and data <= (1 << 31):
				buffer.put_u8(MSGPACK_FORMAT_INT_32)
				buffer.put_32(data)
			else:
				buffer.put_u8(MSGPACK_FORMAT_INT_64)
				buffer.put_64(data)
		
		TYPE_FLOAT:
			buffer.put_u8(MSGPACK_FORMAT_FLOAT_32)
			buffer.put_float(data)
		
		TYPE_STRING:
			var bytes = data.to_utf8_buffer()
			var size = bytes.size()
			if size <= (1 << 5) - 1:
				buffer.put_u8(MSGPACK_FORMAT_FIXSTR | size)
			elif size <= (1 << 8) - 1:
				buffer.put_u8(MSGPACK_FORMAT_STR_8)
				buffer.put_u8(size)
			elif size <= (1 << 16) - 1:
				buffer.put_u8(MSGPACK_FORMAT_STR_16)
				buffer.put_u16(size)
			elif size <= (1 << 32) - 1:
				buffer.put_u8(MSGPACK_FORMAT_STR_32)
				buffer.put_u32(size)
			else:
				@warning_ignore("assert_always_false")
				assert(false)
			buffer.put_data(bytes)
		
		TYPE_PACKED_BYTE_ARRAY:
			var size = data.size()
			if size <= (1 << 8) - 1:
				buffer.put_u8(MSGPACK_FORMAT_BIN_8)
				buffer.put_u8(size)
			elif size <= (1 << 16) - 1:
				buffer.put_u8(MSGPACK_FORMAT_BIN_16)
				buffer.put_u16(size)
			elif size <= (1 << 32) - 1:
				buffer.put_u8(MSGPACK_FORMAT_BIN_32)
				buffer.put_u32(size)
			else:
				@warning_ignore("assert_always_false")
				assert(false)
			buffer.put_data(data)
		
		TYPE_ARRAY:
			var size = data.size()
			if size <= 15:
				buffer.put_u8(MSGPACK_FORMAT_FIXARRAY | size)
			elif size <= (1 << 16) - 1:
				buffer.put_u8(MSGPACK_FORMAT_ARRAY_16)
				buffer.put_u16(size)
			elif size <= (1 << 32) - 1:
				buffer.put_u8(MSGPACK_FORMAT_ARRAY_32)
				buffer.put_u32(size)
			else:
				@warning_ignore("assert_always_false")
				assert(false)
			for obj in data:
				_pack(obj, buffer, error)
				if error.error != OK:
					return
		
		TYPE_DICTIONARY:
			var size = data.size()
			if size <= 15:
				buffer.put_u8(MSGPACK_FORMAT_FIXMAP | size)
			elif size <= (1 << 16) - 1:
				buffer.put_u8(MSGPACK_FORMAT_MAP_16)
				buffer.put_u16(size)
			elif size <= (1 << 32) - 1:
				buffer.put_u8(MSGPACK_FORMAT_MAP_32)
				buffer.put_u32(size)
			else:
				@warning_ignore("assert_always_false")
				assert(false)
			for key in data:
				_pack(key, buffer, error)
				if error.error != OK:
					return
				
				_pack(data[key], buffer, error)
				if error.error != OK:
					return
		_:
			error.error = FAILED
			error.error_string = "Unsupported data type: %s" % [typeof(data)]

func _unpack(buffer, error):
	if buffer.get_position() == buffer.get_size():
		error.error = FAILED
		error.error_string = "unexpected end of input"
		return null
	var head = buffer.get_u8()
	if head == MSGPACK_FORMAT_NIL:
		return null
	
	elif head == MSGPACK_FORMAT_FALSE:
		return false
	
	elif head == MSGPACK_FORMAT_TRUE:
		return true
	
	elif head & MSGPACK_FORMAT_FIXMAP == 0:
		return head
	
	elif (~head) & MSGPACK_FORMAT_NEGATIVE_FIXINT == 0:
		return head - 256
	
	elif head == MSGPACK_FORMAT_UINT_8:
		if buffer.get_size() - buffer.get_position() < 1:
			error.error = FAILED
			error.error_string = "Not enough buffer for uint8"
			return null
		return buffer.get_u8()
	
	elif head == MSGPACK_FORMAT_UINT_16:
		if buffer.get_size() - buffer.get_position() < 2:
			error.error = FAILED
			error.error_string = "Not enough buffer for uint16"
			return null
		return buffer.get_u16()
	
	elif head == MSGPACK_FORMAT_UINT_32:
		if buffer.get_size() - buffer.get_position() < 4:
			error.error = FAILED
			error.error_string = "Not enough buffer for uint32"
			return null
		return buffer.get_u32()
	
	elif head == MSGPACK_FORMAT_UINT_64:
		if buffer.get_size() - buffer.get_position() < 8:
			error.error = FAILED
			error.error_string = "Not enough buffer for uint64"
			return null
		return buffer.get_u64()
	
	elif head == MSGPACK_FORMAT_INT_8:
		if buffer.get_size() - buffer.get_position() < 1:
			error.error = FAILED
			error.error_string = "Not enogh buffer for int8"
			return null
		return buffer.get_8()
	
	elif head == MSGPACK_FORMAT_INT_16:
		if buffer.get_size() - buffer.get_position() < 2:
			error.error = FAILED
			error.error_string = "Not enogh buffer for int16"
			return null
		return buffer.get_16()
	
	elif head == MSGPACK_FORMAT_INT_32:
		if buffer.get_size() - buffer.get_position() < 4:
			error.error = FAILED
			error.error_string = "Not enough buffer for int32"
			return null
		return buffer.get_32()
	
	elif head == MSGPACK_FORMAT_INT_64:
		if buffer.get_size() - buffer.get_position() < 8:
			error.error = FAILED
			error.error_string = "Not enough buffer for int64"
			return null
		return buffer.get_64()
	
	elif head == MSGPACK_FORMAT_FLOAT_32:
		if buffer.get_size() - buffer.get_position() < 4:
			error.error = FAILED
			error.error_string = "Not enough buffer for float32"
			return null
		return buffer.get_float()
	
	elif head == MSGPACK_FORMAT_FLOAT_64:
		if buffer.get_size() - buffer.get_position() < 4:
			error.error = FAILED
			error.error_string = "Not enough buffer for float64"
			return null
		return buffer.get_double()
	
	elif (~head) & MSGPACK_FORMAT_FIXSTR == 0:
		var size = head & 0x1f
		if buffer.get_size() - buffer.get_position() < size:
			error.error = FAILED
			error.error_string = "Not enough buffer for fixstr required %s bytes" % [size]
			return null
		return buffer.get_utf8_string(size)
	
	elif head == MSGPACK_FORMAT_STR_8:
		if buffer.get_size() - buffer.get_position() < 1:
			error.error = FAILED
			error.error_string = "Not enough buffer for str8 size"
			return null
		var size = buffer.get_u8()
		if buffer.get_size() - buffer.get_position() < size:
			error.error = FAILED
			error.error_string = "Not enough buffer for str8 data required %s bytes" % [size]
			return null
		return buffer.get_utf8_string(size)
	
	elif head == MSGPACK_FORMAT_STR_16:
		if buffer.get_size() - buffer.get_position() < 2:
			error.error = FAILED
			error.error_string = "Not enough buffer for str16 size"
			return null
		var size = buffer.get_u16()
		if buffer.get_size() - buffer.get_position() < size:
			error.error = FAILED
			error.error_string = "Not enough buffer for str16 data required %s bytes" % [size]
			return null
		return buffer.get_utf8_string(size)
	
	elif head == MSGPACK_FORMAT_STR_32:
		if buffer.get_size() - buffer.get_position() < 4:
			error.error = FAILED
			error.error_string = "Not enough buffer for str32 size"
			return null
		var size = buffer.get_u32()
		if buffer.get_size() - buffer.get_position() < size:
			error.error = FAILED
			error.error_string = "Not enough buffer for str32 data required %s bytes" % [size]
			return null
		return buffer.get_utf8_string(size)
	
	elif head == MSGPACK_FORMAT_BIN_8:
		if buffer.get_size() - buffer.get_position() < 1:
			error.error = FAILED
			error.error_string = "Not enough buffer for bin8 size"
			return null
		var size = buffer.get_u8()
		if buffer.get_size() - buffer.get_position() < size:
			error.error = FAILED
			error.error_string = "Not enough buffer for bin8 data required %s bytes" % [size]
			return null
		var res = buffer.get_data(size)
		assert(res[0] == OK)
		return res[1]
	
	elif head == MSGPACK_FORMAT_BIN_16:
		if buffer.get_size() - buffer.get_position() < 2:
			error.error = FAILED
			error.error_string = "Not enough buffer for bin16 size"
			return null
		var size = buffer.get_u16()
		if buffer.get_size() - buffer.get_position() < size:
			error.error = FAILED
			error.error_string = "Not enough buffer for bin16 data required %s bytes" % [size]
			return null
		var res = buffer.get_data(size)
		assert(res[0] == OK)
		return res[1]
	
	elif head == MSGPACK_FORMAT_BIN_32:
		if buffer.get_size() - buffer.get_position() < 4:
			error.error = FAILED
			error.error_string = "Not enough buffer for bin32 size"
			return null
		var size = buffer.get_u32()
		if buffer.get_size() - buffer.get_position() < size:
			error.error = FAILED
			error.error_string = "Not enough buffer for bin32 data required %s bytes" % [size]
			return null
		var res = buffer.get_data(size)
		assert(res[0] == OK)
		return res[1]
	
	elif head & 0xf0 == MSGPACK_FORMAT_FIXARRAY:
		var size = head & 0x0f
		var res = []
		for _i in range(size):
			res.append(_unpack(buffer, error))
			if error.error != OK:
				return null
		return res
	
	elif head == MSGPACK_FORMAT_ARRAY_16:
		if buffer.get_size() - buffer.get_position() < 2:
			error.error = FAILED
			error.error_string = "Not enough buffer for array16 size"
			return null
		var size = buffer.get_u16()
		var res = []
		for _i in range(size):
			res.append(_unpack(buffer, error))
			if error.error != OK:
				return null
		return res
	
	elif head == MSGPACK_FORMAT_ARRAY_32:
		if buffer.get_size() - buffer.get_position() < 4:
			error.error = FAILED
			error.error_string = "Not enough buffer for array32 size"
			return null
		var size = buffer.get_u32()
		var res = []
		for _i in range(size):
			res.append(_unpack(buffer, error))
			if error.error != OK:
				return null
		return res
	
	elif head & 0xf0 == MSGPACK_FORMAT_FIXMAP:
		var size = head & 0x0f
		var res = {}
		for _i in range(size):
			var k = _unpack(buffer, error)
			if error.error != OK:
				return null
			var v = _unpack(buffer, error)
			if error.error != OK:
				return null
			res[k] = v
		return res
	
	elif head == MSGPACK_FORMAT_MAP_16:
		if buffer.get_size() - buffer.get_position() < 2:
			error.error = FAILED
			error.error_string = "Not enough buffer for map16 size"
			return null
		var size = buffer.get_u16()
		var res = {}
		for _i in range(size):
			var k = _unpack(buffer, error)
			if error.error != OK:
				return null
			var v = _unpack(buffer, error)
			if error.error != OK:
				return null
			res[k] = v
		return res
	
	elif head == MSGPACK_FORMAT_MAP_32:
		if buffer.get_size() - buffer.get_position() < 4:
			error.error = FAILED
			error.error_string = "Not enough buffer for map32 size"
			return null
		var size = buffer.get_u32()
		var res = {}
		for _i in range(size):
			var k = _unpack(buffer, error)
			if error.error != OK:
				return null
			var v = _unpack(buffer, error)
			if error.error != OK:
				return null
			res[k] = v
		return res
	
	else:
		error.error = FAILED
		error.error_string = "Invalid byte tag %02X at pos %s" % [head, buffer.get_position()]
		return null
