pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.DCommon.Widgets

Column {
    id: root

    required property var settings
    required property string settingKey
    required property string label
    required property var options
    property string description: ""
    property string value: ""
    property bool initialized: false
    readonly property bool isDirty: value !== ""

    width: parent.width
    spacing: Theme.spacingXS
    opacity: enabled ? 1 : 0.5

    function loadValue() {
        initialized = false;
        value = settings.loadValue(settingKey, "");
        initialized = true;
    }
    function resetToDefault() { value = ""; }
    Component.onCompleted: Qt.callLater(loadValue)
    onValueChanged: if (initialized) settings.saveValue(settingKey, value)

    StyledText {
        width: parent.width
        text: root.label
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
    }
    DDropdown {
        width: parent.width
        compactMode: true
        options: root.options.map(option => option.label)
        currentValue: root.options.find(option => option.value === root.value)?.label ?? ""
        onValueChanged: label => {
            const option = root.options.find(option => option.label === label);
            // Empty IDs represent None; do not replace them with the UI label.
            if (option) root.value = option.value;
        }
    }
    StyledText {
        width: parent.width
        visible: root.description !== ""
        text: root.description
        color: Theme.surfaceVariantText
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
    }
}
