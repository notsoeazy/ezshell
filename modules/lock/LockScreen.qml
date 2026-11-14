import Quickshell.Wayland
import qs.services
import qs.modules.lock

// The session lock. WlSessionLock is the secure protocol: the compositor
// shows only these surfaces and gives only them input, and if the shell dies
// the session stays locked. Do not replace it with an ordinary window.
WlSessionLock {
    locked: Lock.locked

    LockSurface {}
}
