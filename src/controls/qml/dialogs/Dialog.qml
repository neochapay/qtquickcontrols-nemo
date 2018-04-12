import QtQuick 2.6
import QtQuick.Controls.Nemo 1.0

Item {
    id: shell
    anchors.fill: parent
    signal accepted()

    property alias acceptText: accept.text
    property alias headingText: heading.text
    property alias subLabelText: subLabel.text

    property real bgOpacity: 1;

    property string icon: ""
    property bool inline: true

    function open(){
        shell.visible = true
    }

    function close(){
        shell.visible = false
    }

    visible: false

    Rectangle {
        id: shadow
        width: parent.width
        height: inline ? (parent.height-accept.height)/3 : parent.height-accept.height
        opacity: shell.bgOpacity
        color: Theme.backgroundColor
        anchors.bottom: accept.top
    }

    Image{
        id: icon
        source: shell.icon
        width: Theme.itemHeightMedium
        height: width
        anchors{
            top: shell.top
            topMargin: Theme.itemSpacingHuge
            horizontalCenter: shell.horizontalCenter
        }
        visible: shell.icon != "" && !inline
        fillMode: Image.PreserveAspectCrop
    }

    Label {
        id: heading
        width: parent.width*0.95
        anchors{
            centerIn: inline ? shadow : parent
        }
        horizontalAlignment: Text.AlignHCenter
        font.weight: Theme.fontWeightLarge
        font.pixelSize:  inline ? Theme.fontSizeTiny : Theme.fontSizeSmall
        wrapMode: Text.Wrap
    }

    Label {
         id:subLabel
         width: parent.width*0.95
         wrapMode: Text.Wrap
         font.weight: Theme.fontWeightMedium
         font.pixelSize:  inline ? Theme.fontSizeTiny : Theme.fontSizeSmall
         horizontalAlignment: Text.AlignHCenter
         anchors {
             top:heading.bottom
             topMargin: inline ? Theme.itemSpacingSmall : Theme.itemSpacingLarge
             horizontalCenter: shell.horizontalCenter
         }
    }

    Button {
        id: accept
        width: parent.width
        height: Theme.itemHeightLarge
        primary: true
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
        onClicked: {
            shell.accepted()
            close();
        }
    }
}
