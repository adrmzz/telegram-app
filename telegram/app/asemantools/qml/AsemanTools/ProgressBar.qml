/*
    Copyright (C) 2014 Aseman
    http://aseman.co

    This project is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This project is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import AsemanTools 1.0

Rectangle {
    id: progress_bar
    width: 100
    height: 6*Devices.density
    color: "#333333"
    radius: 3*Devices.density
    smooth: true

    property real percent: 0
    property alias topColor: top.color

    Rectangle {
        id: top
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: progress_bar.width*progress_bar.percent/100
        //color: masterPalette.highlight
        radius: progress_bar.radius
        visible: width >= radius*2

        Behavior on width {
            NumberAnimation { easing.type: Easing.OutCubic; duration: 100 }
        }
    }

    function setValue( p ){
        percent = p
    }
}
