from __future__ import annotations

import threading
import time
import tkinter as tk
from tkinter import ttk

import cv2

from player import H264Player, LatestFrame
from usbmux_client import connect_device_port, list_usb_devices


class UltraMirrorApp:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title("UltraMirror — مرآة USB")
        self.root.geometry("520x420")
        self.root.configure(bg="#10141c")
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

        self.latest = LatestFrame()
        self.player: H264Player | None = None
        self.running = False
        self.waiting = False
        self.fullscreen = tk.BooleanVar(value=True)

        self._build()
        self.refresh_devices()
        self.root.after(250, self._tick_status)

    def _build(self) -> None:
        title = tk.Label(
            self.root,
            text="مرآة USB",
            fg="white",
            bg="#10141c",
            font=("Segoe UI", 22, "bold"),
        )
        title.pack(pady=(22, 4))
        subtitle = tk.Label(
            self.root,
            text="1080p · 60FPS · أقل تأخير عبر كابل الشحن",
            fg="#9aa4b8",
            bg="#10141c",
            font=("Segoe UI", 11),
        )
        subtitle.pack()

        self.status = tk.Label(
            self.root,
            text="اربط الآيفون ثم اضغط تحديث",
            fg="#e8edf7",
            bg="#10141c",
            font=("Segoe UI", 12),
            wraplength=460,
            justify="center",
        )
        self.status.pack(pady=16)

        self.device_var = tk.StringVar()
        self.device_combo = ttk.Combobox(
            self.root, textvariable=self.device_var, state="readonly", width=48
        )
        self.device_combo.pack(pady=4)

        btns = tk.Frame(self.root, bg="#10141c")
        btns.pack(pady=12)
        tk.Button(btns, text="تحديث الأجهزة", width=16, command=self.refresh_devices).grid(
            row=0, column=0, padx=6
        )
        self.connect_btn = tk.Button(
            btns, text="بدء العرض", width=16, bg="#dc2626", fg="white", command=self.toggle
        )
        self.connect_btn.grid(row=0, column=1, padx=6)

        tk.Checkbutton(
            self.root,
            text="ملء الشاشة",
            variable=self.fullscreen,
            fg="white",
            bg="#10141c",
            selectcolor="#10141c",
            activebackground="#10141c",
            activeforeground="white",
        ).pack()

        help_text = (
            "أولاً على الجوال: اضغط الزر الأحمر واختر مرآة USB\n"
            "لازم يظهر شريط أحمر فوق شاشة الآيفون\n"
            "بعدين هنا اضغط بدء العرض وانتظر\n"
            "الألعاب مثل كود ما تظهر في قائمة البث — افتحها بعد ما يبدأ التسجيل"
        )
        tk.Label(
            self.root,
            text=help_text,
            fg="#7d8799",
            bg="#10141c",
            font=("Segoe UI", 10),
            justify="center",
        ).pack(padx=18, pady=18)

        self.stats = tk.Label(self.root, text="", fg="#cbd5e1", bg="#10141c", font=("Consolas", 11))
        self.stats.pack()

        self._devices: list[dict] = []

    def refresh_devices(self) -> None:
        try:
            self._devices = list_usb_devices()
        except Exception as exc:
            self._devices = []
            self.status.config(text=str(exc))
            self.device_combo["values"] = []
            return
        if not self._devices:
            self.device_combo["values"] = []
            self.status.config(text="ما في آيفون على USB. تأكد من الكابل وApple Devices.")
            return
        labels = [f"{item['name']}  ({item['udid'][:8]}…)" for item in self._devices]
        self.device_combo["values"] = labels
        self.device_combo.current(0)
        self.status.config(text=f"وجد {len(self._devices)} جهاز. ابدأ البث من الجوال ثم اضغط بدء العرض.")

    def toggle(self) -> None:
        if self.running or self.waiting:
            self.stop()
        else:
            self.start()

    def start(self) -> None:
        if not self._devices:
            self.refresh_devices()
        if not self._devices:
            return
        index = self.device_combo.current()
        if index < 0:
            index = 0
        device = self._devices[index]
        self.waiting = True
        self.running = True
        self.connect_btn.config(text="إيقاف")
        self.status.config(text="ينتظر البث من الجوال… اضغط الزر الأحمر على الآيفون واختر مرآة USB.")
        threading.Thread(target=self._connect_loop, args=(device,), daemon=True).start()

    def _connect_loop(self, device: dict) -> None:
        deadline = time.time() + 90
        last_error = "ما بدأ البث بعد."
        while self.running and time.time() < deadline:
            try:
                sock = connect_device_port(int(device["device_id"]))
            except Exception as exc:
                last_error = str(exc)
                remaining = int(deadline - time.time())
                self.root.after(
                    0,
                    lambda r=remaining: self.status.config(
                        text=f"الجوال مربوط. ينتظر بدء البث من الآيفون… ({r} ث)"
                    ),
                )
                time.sleep(1.0)
                continue
            self.waiting = False
            self.latest = LatestFrame()
            self.player = H264Player(sock, self.latest)
            self.player.start()
            self.root.after(0, lambda: self.status.config(text="الكابل متصل. الآن ابدأ البث من الجوال حتى تظهر الصورة."))
            self._display_loop()
            return
        self.waiting = False
        if self.running:
            self.root.after(0, lambda: self.status.config(text=last_error))
            self.root.after(0, self.stop)

    def stop(self) -> None:
        self.running = False
        self.waiting = False
        if self.player:
            self.player.stop()
            self.player = None
        self.connect_btn.config(text="بدء العرض")
        self.status.config(text="توقف العرض.")
        try:
            cv2.destroyAllWindows()
        except Exception:
            pass

    def _display_loop(self) -> None:
        win = "UltraMirror"
        cv2.namedWindow(win, cv2.WINDOW_NORMAL)
        if self.fullscreen.get():
            cv2.setWindowProperty(win, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)
        last_shown = -1
        while self.running:
            with self.latest._lock:
                frame = self.latest.frame
                count = self.latest.frames
            if frame is None or count == last_shown:
                time.sleep(0.002)
                key = cv2.waitKey(1) & 0xFF
                if key in (27, ord("q")):
                    self.root.after(0, self.stop)
                    break
                continue
            last_shown = count
            overlay = frame
            text = f"{self.latest.width}x{self.latest.height}  {self.latest.fps:.0f} FPS"
            cv2.putText(
                overlay,
                text,
                (24, 40),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.8,
                (255, 255, 255),
                2,
                cv2.LINE_AA,
            )
            cv2.imshow(win, overlay)
            key = cv2.waitKey(1) & 0xFF
            if key in (27, ord("q")):
                self.root.after(0, self.stop)
                break
            if key == ord("f"):
                current = cv2.getWindowProperty(win, cv2.WND_PROP_FULLSCREEN)
                cv2.setWindowProperty(
                    win,
                    cv2.WND_PROP_FULLSCREEN,
                    cv2.WINDOW_NORMAL if current == cv2.WINDOW_FULLSCREEN else cv2.WINDOW_FULLSCREEN,
                )
        try:
            cv2.destroyWindow(win)
        except Exception:
            pass

    def _tick_status(self) -> None:
        if self.running:
            if self.latest.error:
                self.status.config(text=self.latest.error)
            self.stats.config(
                text=f"{self.latest.width}x{self.latest.height}   {self.latest.fps:.1f} FPS   frames={self.latest.frames}"
            )
            if not self.latest.alive and self.latest.frames > 0:
                self.status.config(text=self.latest.error or "انقطع البث من الجوال.")
        self.root.after(250, self._tick_status)

    def on_close(self) -> None:
        self.stop()
        self.root.destroy()


def main() -> None:
    root = tk.Tk()
    UltraMirrorApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
