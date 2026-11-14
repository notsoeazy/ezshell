import QtQuick.Layouts
import qs.config
import qs.components.containers
import qs.modules.island
import qs.modules.island.components

// Shown for a moment after something happens: workspaces on the left, the
// clock in the middle, status on the right.
View {
    CenteredRow {
        gap: Tokens.spacing.xxxl
        leading: [
            Logo {},
            Workspaces {
                contained: false
            },
            RecordingIndicator {
                Layout.leftMargin: Tokens.spacing.xs
            }
        ]
        trailing: StatusIcons {}

        Clock {}
    }
}
