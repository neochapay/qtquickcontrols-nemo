/*
 * Copyright (C) 2013 Andrea Bernabei <and.bernabei@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

import QtQuick.Window 2.0
import QtQuick 2.6
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Controls.Private 1.0
import QtQuick.Controls.Nemo 1.0
import QtQuick.Controls.Styles.Nemo 1.0

NemoWindow {
    id: root

    width: 320
    height: 640

    property alias header: toolBar
    /*! \internal */
    default property alias data: contentArea.data

    property alias pageStack: stackView
    property alias initialPage: stackView.initialItem

    property alias orientation: contentArea.uiOrientation
    readonly property int isUiPortrait: root.width < root.height
    //is this safe? can there be some situation in which it's neither portrait nor landscape?
    readonly property int isUiLandscape: !isUiPortrait

    readonly property var _bgColor: Theme.backgroundColor
    color: _bgColor

    //README: allowedOrientations' default value is set in NemoWindow's c++ implementation
    //The app developer can overwrite it from QML

    onAllowedOrientationsChanged: {
        orientationConstraintsChanged()
    }

    Screen.onOrientationChanged: {
        if (root.isOrientationAllowed(Screen.orientation)) {
            contentArea.filteredOrientation = Screen.orientation
        }
    }

    function orientationConstraintsChanged()
    {
        //if the current orientation is not allowed anymore, fallback to an allowed one
        //stackInitialized check prevents setting an orientation before the stackview
        //(but more importantly the initialItem of the stack) has been created
        if (stackView.stackInitialized) {
            //- This is to give priority to the current screen orientation
            //- This case happens when, for example, you're on a landscape only page,
            //  the phone is in portrait, and a page allowing portrait mode is pushed on the stack.
            //  When the page is pushed, we don't get any orientationChanged signal from the Screen element
            //  because the phone was already held in portrait mode, se we have to enforce it here.
            if (isOrientationAllowed(Screen.orientation)) {
                contentArea.filteredOrientation = Screen.orientation
            }
            //- If neither the current screen orientation nor the one which the UI is already presented in (filteredOrientation)
            //  are allowed, then fallback to an allowed orientation.
            else if (!isOrientationAllowed(contentArea.filteredOrientation)) {
                fallbackToAnAllowedOrientation()
            }
        }
    }

    function fallbackToAnAllowedOrientation()
    {
        var orientations = [Qt.PortraitOrientation, Qt.LandscapeOrientation,
                            Qt.InvertedPortraitOrientation, Qt.InvertedLandscapeOrientation]

        //TODO: use a better algo to fall back to the *closest* UI orientation
        //example: don't go from InvertedLandscape to Landscape, but to InvertedPortrait/Portrait, if allowed
        for (var i=0; i<orientations.length; i++) {
            if (isOrientationAllowed(orientations[i])) {
                contentArea.filteredOrientation = orientations[i]
                break
            }
        }
    }

    // TODO: We're assuming default fb orientation of the hw is portrait
    // Soon a compositor fix will be published that will make that consistent on all hw
    // i.e. Screen.width will be width of portrait orientation on all hardware!
    // (at the moment, Screen.width is the width of the screen in landscape mode in N9/N950, while on
    // other hardware it could be width of the screen in portrait mode)
    property bool __transpose: (rotationToTransposeToPortrait() % 180) != 0

    // XXX: This is to account for HW screen rotation
    // Sooner or later we will get rid of this as the compositor will
    // do that for us
    function rotationToTransposeToPortrait()
    {
        switch (Screen.primaryOrientation) {
        case Qt.PortraitOrientation:
            return 0
        case Qt.LandscapeOrientation:
            return -90
        case Qt.InvertedPortraitOrientation:
            return -180
        case Qt.InvertedLandscapeOrientation:
            return -270
        }
    }

    function isOrientationAllowed(orientationToBeChecked)
    {
        var allowedOrientations = root.allowedOrientations

        //use Page's allowed orientations if available
        if (stackView._isCurrentItemNemoPage() && stackView.currentItem.allowedOrientations) {
            allowedOrientations = stackView.currentItem.allowedOrientations
        }

        //check if orientation is part of the allowed orientations mask
        //bit-by-bit AND
        //NOTE: this also returns false if orientationToBeChecked == 0,
        //so we don't need additional checks for that
        return (orientationToBeChecked & allowedOrientations)
    }

    SystemPalette {id: syspal}

    Item {
        id: backgroundItem

        anchors.centerIn: parent
        // NOTE: Using Screen.height/width will cause issues when the app is not fullscreen (e.g. when testing using Qt desktop)
        // because in that case the app window will be smaller but the content will still be for fullscreen size
        width: __transpose ? Screen.height : Screen.width
        height: __transpose ? Screen.width : Screen.height
        rotation: rotationToTransposeToPortrait()

        //This is the rotating item
        Item {
            id: contentArea
            width: parent.width
            height: parent.height
            anchors.centerIn: parent

            property int _horizontalDimension: parent ? parent.width : 0
            property int _verticalDimension: parent ? parent.height : 0

            property alias defaultOrientationTransition: orientationState.defaultTransition

            // This is used for states switching
            property int filteredOrientation

            //this is the reliable value which changes during the orientation transition
            property int uiOrientation

            property bool orientationTransitionRunning: false

            StackView {
                id: stackView
                anchors.top: root.isUiPortrait ? toolBar.bottom : parent.top
                anchors.right: parent.right
                anchors.left: root.isUiPortrait ? parent.left : toolBar.right
                anchors.bottom: parent.bottom

                clip: true
                Component.onCompleted: stackInitialized = true
                //IMPORTANT: this property makes it so that at app startup we wait for the initial page to be pushed
                //before determining the initial ui orientation (see the states logic below)
                //If we don't use this, the orientation will change first time based on NemoWindow's allowedOrientation,
                //and the second time based on the allowedOrientations of the initialItem of the stack.
                //Using this property avoids that, and make the UI directly start in the correct orientation
                //TODO: find a cleaner way to do it (if there's any)
                property bool stackInitialized: false
                onStackInitializedChanged: if (stackInitialized) {
                                               //set Screen.orientation as default, if allowed
                                               if (root.isOrientationAllowed(Screen.orientation)) {
                                                   contentArea.filteredOrientation = Screen.orientation
                                               } else {
                                                   //let the window handle it, it will fall back to an allowed orientation
                                                   root.fallbackToAnAllowedOrientation()
                                               }
                                           }

                //this has to be a function, property won't work inside onCurrentItemChanged, as the property binding hasn't been updated yet there
                //(hence we'd be using the old currentItem)
                function _isCurrentItemNemoPage()
                {
                    return currentItem && currentItem.hasOwnProperty("__isNemoPage")
                }

                //update orientation constraints when a Page is pushed/popped
                onCurrentItemChanged: {
                    if (_isCurrentItemNemoPage())
                        root.orientationConstraintsChanged()
                }

                //This properties are accessible for free by the Page via Stack.view.<property>
                readonly property int orientation: contentArea.uiOrientation
                property alias allowedOrientations: root.allowedOrientations
                property alias orientationTransitionRunning: contentArea.orientationTransitionRunning

                Connections {
                    id: pageConn
                    target: stackView._isCurrentItemNemoPage() ? stackView.currentItem : null
                    onAllowedOrientationsChanged: root.orientationConstraintsChanged()
                }

                delegate: StackViewDelegate {
                    pushTransition: Component {
                        StackViewTransition {
                            PropertyAnimation {
                                target: enterItem
                                property: "x"
                                from: target.width
                                to: 0
                                duration: 500
                                easing.type: Easing.OutQuad
                            }
                            PropertyAnimation {
                                target: exitItem
                                property: "x"
                                from: 0
                                to: -target.width
                                duration: 500
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                    popTransition: Component {
                        StackViewTransition {
                            PropertyAnimation {
                                target: enterItem
                                property: "x"
                                from: -target.width
                                to: 0
                                duration: 500
                                easing.type: Easing.OutQuad
                            }
                            PropertyAnimation {
                                target: exitItem
                                property: "x"
                                from: 0
                                to: target.width
                                duration: 500
                                easing.type: Easing.OutQuad
                            }
                        }
                    }

                }
            }

            Header {
                id: toolBar
                stackView: root.pageStack
                appWindow: root

                //used to animate the dimmer when pages are pushed/popped (see Header's QML code)
                property alias __dimmer: headerDimmerContainer
            }

            Item {
                //This item handles the rotation of the dimmer.
                //All this because QML doesn't have a horizontal gradient (unless you import GraphicalEffects)
                //and having a container which doesn't rotate but just resizes makes it easier to rotate its inner
                //child
                id: headerDimmerContainer

                //README: Don't use AnchorChanges for this item!
                //Reason: state changes disable bindings while the transition from one state to another is running.
                //This causes the dimmer not to follow the drawer when the drawer is closed right before the orientation change
                anchors.top: isUiPortrait ? toolBar.bottom : parent.top
                anchors.left: isUiPortrait ? parent.left : toolBar.right
                anchors.right: isUiPortrait ? parent.right : undefined
                anchors.bottom: isUiPortrait ? undefined : parent.bottom
                //we only set the size in one orientation, the anchors will take care of the other
                width: if (!isUiPortrait) Theme.itemHeightExtraSmall/2
                height: if (isUiPortrait) Theme.itemHeightExtraSmall/2
                //MAKE SURE THAT THE HEIGHT SPECIFIED BY THE THEME IS AN EVEN NUMBER, TO AVOID ROUNDING ERRORS IN THE LAYOUT

                Rectangle {
                    id: headerDimmer
                    anchors.centerIn: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: Theme.backgroundColor }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }
            }

            Item {
                id: orientationState

                state: 'Unanimated'

                states: [
                    State {
                        name: 'Unanimated'
                        when: !stackView || !stackInitialized
                    },
                    State {
                        name: 'Portrait'
                        when: contentArea.filteredOrientation === Qt.PortraitOrientation// && stackInitialized
                        PropertyChanges {
                            target: contentArea
                            restoreEntryValues: false
                            width: _horizontalDimension
                            height: _verticalDimension
                            rotation: 0
                            uiOrientation: Qt.PortraitOrientation
                        }
                        PropertyChanges {
                            target: headerDimmer
                            height: Theme.itemHeightExtraSmall/2
                            width: parent.width
                            rotation: 0
                        }
                    },
                    State {
                        name: 'Landscape'
                        when: contentArea.filteredOrientation === Qt.LandscapeOrientation //&& stackInitialized
                        PropertyChanges {
                            target: contentArea
                            restoreEntryValues: false
                            width: _verticalDimension
                            height: _horizontalDimension
                            rotation: 90
                            uiOrientation: Qt.LandscapeOrientation
                        }
                        PropertyChanges {
                            target: headerDimmer
                            height: Theme.itemHeightExtraSmall/2
                            width: parent.height
                            rotation: -90
                        }
                    },
                    State {
                        name: 'PortraitInverted'
                        when: contentArea.filteredOrientation === Qt.InvertedPortraitOrientation //&& stackInitialized
                        PropertyChanges {
                            target: contentArea
                            restoreEntryValues: false
                            width: _horizontalDimension
                            height: _verticalDimension
                            rotation: 180
                            uiOrientation: Qt.InvertedPortraitOrientation
                        }
                        PropertyChanges {
                            target: headerDimmer
                            height: Theme.itemHeightExtraSmall/2
                            width: parent.width
                            rotation: 0
                        }
                    },
                    State {
                        name: 'LandscapeInverted'
                        when: contentArea.filteredOrientation === Qt.InvertedLandscapeOrientation //&& stackInitialized
                        PropertyChanges {
                            target: contentArea
                            restoreEntryValues: false
                            width: _verticalDimension
                            height: _horizontalDimension
                            rotation: 270
                            uiOrientation: Qt.InvertedLandscapeOrientation
                        }
                        PropertyChanges {
                            target: headerDimmer
                            height: Theme.itemHeightExtraSmall/2
                            width: parent.height
                            rotation: -90
                        }
                    }
                ]

                property Transition defaultTransition: Transition {
                    to: 'Portrait,Landscape,PortraitInverted,LandscapeInverted'
                    from: 'Portrait,Landscape,PortraitInverted,LandscapeInverted'
                    SequentialAnimation {
                        PropertyAction {
                            target: contentArea
                            property: 'orientationTransitionRunning'
                            value: true
                        }
                        NumberAnimation {
                            target: contentArea
                            property: 'opacity'
                            to: 0
                            duration: 150
                        }
                        PropertyAction {
                            target: contentArea
                            properties: 'width,height,rotation,uiOrientation'
                        }
                        AnchorAnimation {
                            duration: 0
                        }
                        PropertyAction {
                            target: headerDimmer
                            properties: 'width,height,rotation'
                        }
                        NumberAnimation {
                            target: contentArea
                            property: 'opacity'
                            to: 1
                            duration: 150
                        }
                        PropertyAction {
                            target: contentArea
                            property: 'orientationTransitionRunning'
                            value: false
                        }
                    }
                }

                Component.onCompleted: {
                    if (transitions.length === 0) {
                        transitions = [ defaultTransition ]
                    }
                }
            }
        }
    }
}

