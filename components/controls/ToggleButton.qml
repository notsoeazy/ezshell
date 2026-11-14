import qs.components.controls

// A round icon button that stays lit while something is on: filled with the
// accent colour, icon filled in. This is the HIG's toggle for outside a list,
// where a switch does not belong.
//
//   checked   whether it is on; the owner changes it in `onActivated`
//   icon, size, iconSize   as IconButton
//   onSecondaryActivated   right click, for opening related options
IconButton {
    property bool checked

    style: checked ? Button.Filled : Button.Gray
    iconFilled: checked
}
