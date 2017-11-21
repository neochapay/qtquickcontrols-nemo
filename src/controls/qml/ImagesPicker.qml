import QtQuick 2.6
import QtQuick.Controls.Nemo 1.0
import Nemo.UX.Models 1.0

GridView {
    id: imagesPicker
    cellHeight: cellWidth
    cellWidth: parent.width/3

    property alias rootDir: imagesModel.rootDir
    property alias showDirs: imagesModel.showDirs

    property bool multiSelect: false
    property var selectedImages: []

    signal deselectAll();

    ImagesListModel{
        id: imagesModel
        previewCout: 4
    }

    model: imagesModel

    delegate: Rectangle{
        id: imageDelegate
        width: imagesPicker.cellWidth
        height: width

        property bool selected: false
        property bool isDir: model.isDir

        property var previewsModel: []

        color: Theme.backgroundColor

        Component.onCompleted: {
            if(imageDelegate.isDir)
            {
                if(model.previews.length == 0)
                {
                    previewsModel = ["image://theme/folder"]
                }
                else
                {
                    previewsModel = model.previews
                }
            }
            else
            {
                previewsModel = [model.path]
            }
        }

        GridView{
            id: previewGrid

            clip: true

            width: imageDelegate.width
            height: imageDelegate.height

            cellWidth: (previewsModel.length > 1) ? previewGrid.width/2 : previewGrid.width
            cellHeight: previewGrid.cellWidth
            model: previewsModel
            delegate: Image{
                width: previewGrid.cellWidth
                height: previewGrid.cellHeight
                fillMode: Image.PreserveAspectCrop
                source: modelData
            }
        }

        Rectangle{
            id: selectedBorder
            width: parent.width
            height: parent.height
            color: "transparent"
            border.color: Theme.accentColor
            border.width: parent.width/40
            visible: imageDelegate.selected
        }

        Connections{
            target: imagesPicker
            onDeselectAll: imageDelegate.selected = false
        }

        MouseArea{
            anchors.fill: parent
            onPressAndHold: {
                if(!model.isDir)
                {
                    if(!imagesPicker.multiSelect)
                    {
                        imagesPicker.deselectAll();
                    }

                    if(imageDelegate.selected)
                    {
                        imageDelegate.selected = false
                    }
                    else
                    {
                        imageDelegate.selected = true
                    }
                }
            }
            onClicked: {
                if(model.isDir)
                {
                    imagesModel.rootDir = model.path
                    console.log(model.path)
                }
            }
        }
    }
}
