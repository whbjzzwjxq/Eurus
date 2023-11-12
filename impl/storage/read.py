from typing import Dict, List, Tuple
from subprocess import run

from eth_utils import decode_hex, keccak

from .utils import *


def read_from_slot(bytes_data: bytes, offset: int, length: int) -> bytes:
    start = max(SLOT_SIZE - offset - length, 0)
    end = min(start + length, SLOT_SIZE)
    return bytes_data[start:end]


def read_from_storage(addr: str, slot: str) -> bytes:
    cmd = [
        "cast",
        "storage",
        "--silent",
        addr,
        slot,
    ]
    result = run(cmd, capture_output=True, text=True)
    return decode_hex(result.stdout.strip())


def read_from_storage_by_bytes(addr: str, slot: bytes) -> str:
    return read_from_storage(addr, slot.hex())


def read_from_storage_by_int(addr: str, slot: int) -> str:
    return read_from_storage(addr, hex(slot))


class StorageDescriber:
    def __init__(self, storage_describer: dict):
        self.ast_id: int = storage_describer["astId"]
        self.contract: str = storage_describer["contract"]
        self.label: str = storage_describer["label"]
        self.offset: int = storage_describer["offset"]
        self.slot: str = storage_describer["slot"]
        self.type: str = storage_describer["type"]


class TypeDescriber:
    def __init__(self, type_name: str, types_layout: dict):
        if type_name not in types_layout:
            raise Exception("Unknown type_name")

        type_describer: dict = types_layout[type_name]
        self.type_name = type_name
        self.encoding = type_describer["encoding"]
        self.label = type_describer["label"]
        self.numberOfBytes = type_describer["numberOfBytes"]

        if "key" in type_describer:
            self.is_mapping = True
            self.key = TypeDescriber(type_describer["key"], types_layout)
            self.value = TypeDescriber(type_describer["value"], types_layout)
        elif "base" in type_describer:
            self.is_array = True
            self.base = TypeDescriber(type_describer["base"], types_layout)
        elif "members" in type_describer:
            self.is_struct = True
            self.members = [
                StorageDescriber(member) for member in type_describer["members"]
            ]

    def is_ref(self):
        return self.is_mapping or self.is_array or self.is_struct


StorageLayout = Tuple[List[StorageDescriber], Dict[str, TypeDescriber]]


class ValueType:
    def __init__(self, bytes_count: int, type_str: str):
        self.bytes_count = bytes_count
        self.type_str = type_str
        self.basic_type = "ValueType"

    def decode_value(self, data: bytes) -> str:
        raise NotImplementedError

    def gen_getter(self, ctrt_addr: str, base: bytes) -> "Getter":
        return None

    def next_slot_key(self, last_slot_key: str, step: int) -> str:
        if step == 0:
            new_slot_idx = last_slot_key
        else:
            idx = int(last_slot_key, 16)
            idx += step
            new_slot_idx = hex(idx)
        return new_slot_idx

    def read_bytes(self, ctrt_addr: str, slot_idx: int, offset: int) -> bytes:
        result = bytes()
        len = self.bytes_count
        last_slot_key = hex(slot_idx)
        while len > 0:
            last_slot_key = self.next_slot_key(last_slot_key, 0)
            value = read_from_storage(ctrt_addr, last_slot_key)
            temp = read_from_slot(value, offset, len)
            result += temp
            len -= SLOT_SIZE
        return result

    def decode(self, ctrt_addr: str, slot_idx: int, offset: int) -> str:
        bytes_data = self.read_bytes(ctrt_addr, slot_idx, offset)
        return self.decode_value(bytes_data)

    def is_normal_type(self) -> bool:
        return self.basic_type == "ValueType"


class Address(ValueType):
    def __init__(self):
        super().__init__(20, "address")

    def decode_value(self, data: bytes) -> str:
        return "0x" + data.hex()


class Bool(ValueType):
    def __init__(self):
        super().__init__(1, "bool")

    def decode_value(self, data: bytes) -> str:
        return str(data != b"\x00")


class Bytes(ValueType):
    def __init__(self):
        super().__init__(32, "bytes")

    def read_bytes(self, ctrt_addr: str, slot_idx: str, offset: int) -> bytes:
        main_slot = read_from_storage(ctrt_addr, slot_idx)
        checkbit = main_slot[-1]
        result = bytearray()
        if checkbit % 2 == 0:
            result = read_from_slot(main_slot, 0, 32)
            if len(result) > 0:
                result.pop()
        else:
            len_ = int.from_bytes(main_slot, "big")
            len_ = (len_ - 1) // 2
            main_slot_key = slot_idx.zfill(SLOT_SIZE * 2)
            slot_key = keccak(bytes.fromhex(main_slot_key))
            slot_hash = int.from_bytes(slot_key, "big")
            while len_ > 0:
                cur_bytes32 = read_from_storage_by_int(ctrt_addr, slot_hash)
                len_temp = min(len_, SLOT_SIZE)
                temp = read_from_slot(cur_bytes32, 0, len_temp)
                result.extend(temp)
                len_ -= SLOT_SIZE
                slot_hash += 1
        return bytes(result)

    def decode_value(self, data: bytes) -> str:
        return "0x" + data.hex()


class Enum(ValueType):
    def __init__(self):
        super().__init__(1, "enum")

    def decode_value(self, data: bytes) -> str:
        if len(data) != 1:
            raise Exception("Invalid enum data")
        return str(data[0])


class FixedByteArray(ValueType):
    def __init__(self, bytes_count: int):
        super().__init__(bytes_count, "fixed" + str(bytes_count))

    def decode_value(self, data: bytes) -> str:
        return "0x" + data.hex()


class UInt(ValueType):
    def __init__(self, bytes_count: int):
        super().__init__(bytes_count, "uint" + str(bytes_count * 8))

    def decode_value(self, data: bytes) -> str:
        return int.from_bytes(data, byteorder="big")


class String(Bytes):
    def __init__(self):
        super().__init__()
        self.type_str = "string"

    def decode_value(self, data: bytes) -> str:
        return data.decode("utf-8")


class ContainerType(ValueType):
    def __init__(self, type_str: str):
        super().__init__(32, type_str)
        self.basic_type = "ContainerType"

    def decode_value(self, data: bytes) -> str:
        return ""

    def decode(self, ctrt_addr: str, slot_idx: int, offset: int) -> str:
        return ""


class Mapping(ContainerType):
    def __init__(self, key_t: ValueType, value_t: ValueType, type_str: str):
        super().__init__(type_str)
        self.key_t = key_t
        self.value_t = value_t

    def gen_getter(self, ctrt_addr: str, base: bytes):
        return MappingGetter(self, ctrt_addr, base)


class DynamicByteArray(ContainerType):
    def __init__(self, base_t, type_str: str):
        super().__init__(type_str)
        self.base_t = base_t

    def gen_getter(self, ctrt_addr: str, base: bytes):
        return DynamicByteArrayGetter(self, ctrt_addr, base)


class Struct(ContainerType):
    def __init__(self, members, members_t, type_str: str):
        super().__init__(type_str)
        self.members = members
        self.members_t = members_t

    def gen_getter(self, ctrt_addr: str, base: bytes):
        return StructGetter(self, ctrt_addr, base)


class Getter:
    def __init__(self, ctrt_addr: str, base: bytes):
        self.ctrt_addr = ctrt_addr
        self.base = base
        self.depth = 0

    def get(self, keys: List[str], depth: int, base: bytes) -> str:
        raise NotImplementedError


class MappingGetter(Getter):
    def __init__(self, type_info: Mapping, ctrt_addr: str, base: bytes):
        super().__init__(ctrt_addr, base)
        if type_info.value_t.is_normal_type():
            self.next_getter: Getter = None
            self.depth = 1
            self.value_t: ValueType = type_info.value_t
        else:
            self.next_getter: Getter = type_info.value_t.gen_getter(ctrt_addr, base)
            self.depth = self.next_getter.depth + 1
            self.value_t: ValueType = type_info.value_t
        self.is_key_padding = type_info.key_t.type_str not in ("string", "bytes")

    def size(self):
        return 0

    def count_address(self, base: bytes, index: bytes):
        key = index + base
        return keccak(key)

    def get(self, keys: List[str], depth: int, base: bytes):
        cur_key: bytes = decode_hex(keys[depth])
        if self.is_key_padding:
            cur_key = pad_bytes(cur_key, SLOT_SIZE)
        address = self.count_address(base, cur_key)
        if self.depth == 1:
            address_hex = address.hex()
            return self.value_t.decode(self.ctrt_addr, address_hex, 0)
        else:
            return self.next_getter.get(keys, depth + 1, address)


class DynamicByteArrayGetter(Getter):
    def __init__(self, type_info: TypeDescriber, ctrt_addr: str, base: bytes):
        super().__init__(ctrt_addr, base)
        self.base_t = type_info.base_t
        self.final_t = type_info.base_t
        self.next_getter = None
        self.depth = 1

    def size(self):
        base_bytes = read_from_storage_by_bytes(self.base, self.ctrt_addr)
        i = 256 // (self.final_t.bytes_count * 8)
        return int.from_bytes(base_bytes, "big", signed=False) // i

    def count_address(self, base: bytes, index: bytes):
        i = 256 // (self.final_t.bytes_count * 8)
        offset = int.from_bytes(index, "big", signed=False) // i
        return offset_bytes32(keccak(base), offset)

    def get(self, keys: List[str], depth: int, base: bytes):
        cur_key = keys[depth]
        index = int.from_bytes(cur_key, "big", signed=False)
        address = self.count_address(base, cur_key)
        if index >= self.size():
            raise Exception("Index out of range")
        if self.depth == 1:
            return self.final_t.decode(self.ctrt_addr, address.hex(), 0)
        else:
            return self.next_getter.get(keys, depth + 1, address)


class StructGetter(Getter):
    def __init__(self, type_info: TypeDescriber, ctrt_addr: str, base: bytes):
        super().__init__(ctrt_addr, base)
        self.members_name = [member.label for member in type_info.members]
        self.members = type_info.members
        self.members_t = type_info.members_t
        self.members_getter = [
            member_t.gen_getter(ctrt_addr) if not member_t.is_normal_type() else None
            for member_t in type_info.members_t
        ]
        self.depth = max(
            [getter.depth + 1 if getter else 1 for getter in self.members_getter]
        )

    def size(self):
        return len(self.members)

    def count_address(self, base: bytes, index: bytes):
        return offset_bytes32(base, int(index))

    def index_of(self, prop_name: str):
        for i, name in enumerate(self.members_name):
            if name == prop_name:
                return i
        raise Exception("Unknown prop_name")

    def get(self, keys: List[str], depth: int, base: bytes):
        cur_key = keys[depth]
        index = self.members_name.index(cur_key)
        if index >= self.size():
            raise Exception("Index out of range")
        stor_info = self.members[index]
        address = self.count_address(base, stor_info.slot)
        getter = self.members_getter[index]
        if getter is None:
            type_info = self.members_t[index]
            return type_info.decode(self.ctrt_addr, address.hex(), stor_info.offset)
        else:
            return getter.get(keys, depth + 1, address)


def get_type(type_info: TypeDescriber, type_def_mapping: Dict[str, TypeDescriber]):
    label = type_info.label
    bytes_count = int(type_info.numberOfBytes)
    _type = None

    if label.endswith("[]"):
        base_t = get_type(type_info.base, type_def_mapping)
        _type = DynamicByteArray(base_t, label)
    elif label.startswith("address"):
        _type = Address()
    elif label.startswith("bool"):
        _type = Bool()
    elif label.startswith("bytes"):
        _type = Bytes()
    elif label.startswith("enum"):
        _type = Enum()
    elif label.startswith("fixedArray"):
        _type = FixedByteArray(bytes_count)
    elif label.startswith("uint"):
        _type = UInt(bytes_count)
    elif label.startswith("string"):
        _type = String()
    elif label.startswith("mapping"):
        key_t = get_type(type_info.key, type_def_mapping)
        value_t = get_type(type_info.value, type_def_mapping)
        _type = Mapping(key_t, value_t, label)
    elif label.startswith("struct"):
        members_t = [
            get_type(type_def_mapping[p.type], type_def_mapping)
            for p in type_info.members
        ]
        _type = Struct(type_info.members, members_t, label)
    else:
        raise Exception("Unknown type")
    return _type


def get_var(
    ctrt_addr: str, var_name: str, keys: List[str], storage_layout: StorageLayout
) -> str:
    label_defs, type_def_mapping = storage_layout
    stor_infos = [l for l in label_defs if l.label == var_name]
    if len(stor_infos) == 0:
        raise ValueError(f"Unknown varirable: {var_name}")
    stor_info = stor_infos[0]
    type_info = type_def_mapping[stor_info.type]
    _type = get_type(type_info, type_def_mapping)
    if len(keys) != 0:
        getter: Getter = _type.gen_getter(ctrt_addr, stor_info.slot)
        result = getter.get(keys, 0, slot_num2bytes(stor_info.slot))
    else:
        result = _type.decode(ctrt_addr, int(stor_info.slot), stor_info.offset)
    return result
