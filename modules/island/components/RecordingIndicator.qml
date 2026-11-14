import qs.components
import qs.services

// A screen recording in progress, as a red dot that breathes. Takes no space
// otherwise.
Reveal {
    shown: Capture.recording
    collapse: Reveal.Horizontal
    fromScale: 0.6

    RecordingDot {}
}
