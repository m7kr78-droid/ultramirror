"""Decode a raw Annex-B H.264 socket with the smallest possible buffer."""

from __future__ import annotations

import socket
import threading
import time
from typing import Optional

import av
import numpy as np


class LatestFrame:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self.frame: Optional[np.ndarray] = None
        self.fps = 0.0
        self.width = 0
        self.height = 0
        self.frames = 0
        self.error: Optional[str] = None
        self.alive = False


class H264Player:
    def __init__(self, sock: socket.socket, latest: LatestFrame) -> None:
        self._sock = sock
        self.latest = latest
        self._stop = threading.Event()
        self._thread: Optional[threading.Thread] = None

    def start(self) -> None:
        self.latest.alive = True
        self.latest.error = None
        self._thread = threading.Thread(target=self._run, name="h264-decode", daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        try:
            self._sock.shutdown(socket.SHUT_RDWR)
        except OSError:
            pass
        try:
            self._sock.close()
        except OSError:
            pass
        self.latest.alive = False

    def _run(self) -> None:
        options = {
            "fflags": "nobuffer+discardcorrupt",
            "flags": "low_delay",
            "probesize": "32768",
            "analyzeduration": "0",
            "sync": "ext",
        }
        try:
            container = av.open(
                self._sock.makefile("rb", buffering=0),
                format="h264",
                mode="r",
                options=options,
            )
        except Exception as exc:
            self.latest.error = f"فشل فتح الفيديو: {exc}"
            self.latest.alive = False
            return

        codec = container.streams.video[0].codec_context
        codec.low_delay = True
        codec.thread_count = 1
        codec.thread_type = "SLICE"

        last = time.perf_counter()
        shown = 0
        try:
            for frame in container.decode(video=0):
                if self._stop.is_set():
                    break
                image = frame.to_ndarray(format="bgr24")
                now = time.perf_counter()
                shown += 1
                if now - last >= 0.5:
                    self.latest.fps = shown / (now - last)
                    shown = 0
                    last = now
                with self.latest._lock:
                    self.latest.frame = image
                    self.latest.width = image.shape[1]
                    self.latest.height = image.shape[0]
                    self.latest.frames += 1
        except Exception as exc:
            if not self._stop.is_set():
                self.latest.error = f"انقطع البث: {exc}"
        finally:
            try:
                container.close()
            except Exception:
                pass
            self.latest.alive = False
