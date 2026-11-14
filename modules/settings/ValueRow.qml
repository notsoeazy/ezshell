import qs.components
import qs.components.containers

// A row that only states something: a name and its value.
ListRow {
    id: root

    property string value

    interactive: false

    Label {
        text: root.value
        level: Label.Secondary
    }
}
