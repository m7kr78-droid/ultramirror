"""Connect to the iPhone over USB using Apple's usbmuxd service (iTunes / Apple Devices)."""

from __future__ import annotations

import plistlib
import socket
import struct
from typing import Any


USBMUX_HOST = "127.0.0.1"
USBMUX_PORT = 27015
DEVICE_STREAM_PORT = 17420
HEADER_SIZE = 16
PLIST_PACKET = 8


def _pack_port(port: int) -> int:
    return socket.htons(port)


def _recvall(sock: socket.socket, length: int) -> bytes:
    chunks = bytearray()
    while len(chunks) < length:
        piece = sock.recv(length - len(chunks))
        if not piece:
            raise ConnectionError("usbmux connection closed")
        chunks.extend(piece)
    return bytes(chunks)


def _send_plist(sock: socket.socket, payload: dict[str, Any], tag: int = 1) -> None:
    body = plistlib.dumps(payload, fmt=plistlib.FMT_XML)
    header = struct.pack("<IIII", HEADER_SIZE + len(body), 1, PLIST_PACKET, tag)
    sock.sendall(header + body)


def _recv_plist(sock: socket.socket) -> dict[str, Any]:
    header = _recvall(sock, HEADER_SIZE)
    length, _version, _ptype, _tag = struct.unpack("<IIII", header)
    body = _recvall(sock, length - HEADER_SIZE)
    return plistlib.loads(body)


def _open_usbmux() -> socket.socket:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    sock.settimeout(3)
    try:
        sock.connect((USBMUX_HOST, USBMUX_PORT))
    except OSError as exc:
        raise ConnectionError(
            "ما قدر يتصل بخدمة Apple USB. ثبت iTunes أو Apple Devices من Microsoft Store."
        ) from exc
    sock.settimeout(8)
    return sock


def list_usb_devices() -> list[dict[str, Any]]:
    sock = _open_usbmux()
    try:
        _send_plist(
            sock,
            {
                "MessageType": "ListDevices",
                "ClientVersionString": "UltraMirror-1.0",
                "ProgName": "UltraMirror",
            },
        )
        response = _recv_plist(sock)
    finally:
        sock.close()

    devices = []
    for item in response.get("DeviceList", []):
        props = item.get("Properties", {})
        if props.get("ConnectionType") not in (None, "USB"):
            continue
        devices.append(
            {
                "device_id": item.get("DeviceID"),
                "udid": props.get("SerialNumber", ""),
                "name": props.get("DeviceName") or props.get("ProductType") or "iPhone",
            }
        )
    return devices


def connect_device_port(device_id: int, port: int = DEVICE_STREAM_PORT) -> socket.socket:
    sock = _open_usbmux()
    _send_plist(
        sock,
        {
            "MessageType": "Connect",
            "ClientVersionString": "UltraMirror-1.0",
            "ProgName": "UltraMirror",
            "DeviceID": device_id,
            "PortNumber": _pack_port(port),
        },
    )
    response = _recv_plist(sock)
    if int(response.get("Number", 1)) != 0:
        sock.close()
        raise ConnectionError(
            "الجوال مربوط بس البث مو شغال. افتح مرآة USB على الآيفون واضغط زر البث."
        )
    sock.settimeout(None)
    sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    return sock
