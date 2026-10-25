"""winperf.py - Windows helpers: priority, 1 ms timer, no power throttling, keep awake, single instance.
Fallback version written to match the log line of the original ("priority,timer1ms,no-throttle,awake").
If you have your own original winperf.py you may replace this file with it."""
import sys
import ctypes

_keep = []


def _k32():
    return ctypes.WinDLL("kernel32", use_last_error=True)


def single_instance():
    """False if CuteVoice is already running."""
    if sys.platform != "win32":
        return True
    try:
        h = _k32().CreateMutexW(None, False, "Local\\CuteVoiceStudioV3")
        _keep.append(h)
        return ctypes.get_last_error() != 183            # ERROR_ALREADY_EXISTS
    except Exception:
        return True


def boost_process():
    """Called once at start (and on every START). Returns a short text for the log."""
    if sys.platform != "win32":
        return "n/a"
    out = []
    k = None
    try:
        k = _k32()
        if k.SetPriorityClass(k.GetCurrentProcess(), 0x8000):           # ABOVE_NORMAL_PRIORITY_CLASS
            out.append("priority")
    except Exception:
        pass
    try:
        ctypes.WinDLL("winmm").timeBeginPeriod(1)
        out.append("timer1ms")
    except Exception:
        pass
    try:                                                                  # opt out of EcoQoS / power throttling
        class _PT(ctypes.Structure):
            _fields_ = [("Version", ctypes.c_ulong), ("ControlMask", ctypes.c_ulong), ("StateMask", ctypes.c_ulong)]
        st = _PT(1, 1, 0)                                                 # PROCESS_POWER_THROTTLING_EXECUTION_SPEED off
        if k is not None and k.SetProcessInformation(k.GetCurrentProcess(), 4, ctypes.byref(st), ctypes.sizeof(st)):
            out.append("no-throttle")
    except Exception:
        pass
    try:
        if k is not None and k.SetThreadExecutionState(0x80000001):       # ES_CONTINUOUS | ES_SYSTEM_REQUIRED
            out.append("awake")
    except Exception:
        pass
    return ",".join(out) or "none"


def boost_thread():
    """Called from the audio worker thread: highest thread priority + MMCSS 'Pro Audio'."""
    if sys.platform != "win32":
        return
    try:
        k = _k32()
        k.SetThreadPriority(k.GetCurrentThread(), 2)       # THREAD_PRIORITY_HIGHEST
    except Exception:
        pass
    try:
        idx = ctypes.c_ulong(0)
        ctypes.WinDLL("avrt").AvSetMmThreadCharacteristicsW("Pro Audio", ctypes.byref(idx))
    except Exception:
        pass
