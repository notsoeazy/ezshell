import qs.components.controls

// HIG search field: a text field with a magnifier and a clear button. Escape
// clears the query first, and only then passes to whatever is behind it.
TextField {
    leadingIcon: "search"
    placeholder: "Search"
    clearable: true
}
