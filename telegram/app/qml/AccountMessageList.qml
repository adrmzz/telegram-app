import QtQuick 2.0
import Ubuntu.Components 1.2
import Ubuntu.Components 1.2 as UC
import Ubuntu.Content 0.1
import AsemanTools.Controls 1.0 as Controls

import AsemanTools 1.0
import TelegramQML 1.0

import "qrc:/qml/ui"
import "qrc:/qml/components"

Rectangle {
    id: acc_msg_list

    property alias telegramObject: messages_model.telegram
    property alias currentDialog: messages_model.dialog
    property alias refreshing: messages_model.refreshing

    readonly property bool inSelectionMode: mlist.isInSelectionMode
    readonly property int selectedItemCount: mlist.selectedItems.count
    readonly property int totalItemCount: mlist.listModel.count

    property real topMargin
    property real bottomMargin

    property real maximumMediaHeight: maximumMediaWidth
    // This is neat, but I don't like it resizes the photo live: (height-topMargin-bottomMargin)*0.75
    property real maximumMediaWidth: width*0.75

    property bool isActive: View.active && View.visible
    property bool messageDraging: false

    property string selectedText

    property alias maxId: messages_model.maxId

    property bool isChat: currentDialog ? currentDialog.peer.chatId != 0 : false

    property EncryptedChat enchat: telegramObject.encryptedChat(currentDialog.peer.userId)
    property int enChatUid: enchat.adminId==telegramObject.me? enchat.participantId : enchat.adminId

    property int filterId: -1

    property real typeEncryptedChatWaiting: 0x3bf703dc
    property real typeEncryptedChatRequested: 0xc878527e
    property real typeEncryptedChatEmpty: 0xab7ec0a0
    property real typeEncryptedChatDiscarded: 0x13d6dd27
    property real typeEncryptedChat: 0xfa56ce36

    signal forwardRequest(variant messageIds)
    signal focusRequest()
    signal dialogRequest(variant dialogObject)
    signal tagSearchRequest(string tag)
    signal replyToRequest(int msgId)

    onIsActiveChanged: {
        if( isActive )
            messages_model.setReaded()
    }

    onCurrentDialogChanged: {
        selected_list.clear()
        add_anim_disabler.restart()
    }

    ListObject {
        id: selected_list
    }

    MessagesModel {
        id: messages_model
        onCountChanged: {
            if(count>1 && isActive)
                messages_model.setReaded()
        }
        onRefreshingChanged: {
            if(focus_msg_timer.msgId) {
                if(refreshing)
                    focus_msg_timer.stop()
                else
                    focus_msg_timer.restart()
            }
        }
        onFocusToNewRequest: {
            if(!hasNewMessage) {
                return;
            }

            focus_msg_timer.msgIndex = unreads>0? unreads-1 : 0
            focus_msg_timer.restart()
        }
    }

    // Timer {
    //     id: refresh_timer
    //     repeat: true
    //     interval: 10000
    //     onTriggered: messages_model.refresh()
    //     Component.onCompleted: start()
    // }

    Image {
        anchors.fill: parent
        fillMode: Cutegram.background.length==0? Image.Tile : Image.PreserveAspectCrop
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        sourceSize: Cutegram.background.length==0? Cutegram.imageSize("qrc:/qml/files/telegram_background.png") : Qt.size(width,height)
        source: {
            return "qrc:/qml/files/telegram_background.png"
//            if(backgroundManager.background == "")
//                return Cutegram.background.length==0? "qrc:/qml/files/telegram_background.png" : Devices.localFilesPrePath + Cutegram.background
//            else
//                return backgroundManager.background
        }
        opacity: 0.7
    }

    Rectangle {
        anchors.centerIn: parent
        color: "#ffffff"
        width: welcome_txt.width + 20*Devices.density
        height: welcome_txt.height + 10*Devices.density
        radius: 5*Devices.density
        visible: currentDialog == telegramObject.nullDialog

        Text {
            id: welcome_txt
            anchors.centerIn: parent
            font.pixelSize: Math.floor((Cutegram.font.pointSize+1)*Devices.fontDensity)
            font.family: Cutegram.font.family
            text: i18n.tr("Please select chat")
            color: "#111111"
        }
    }

    Timer {
        id: anim_enabler_timer
        interval: 400
    }

    Timer {
        id: file_delete_timer
        interval: 1000
        onTriggered: Cutegram.deleteFile(filePath)

        property string filePath
    }

    Timer {
        id: add_anim_disabler
        interval: 500
    }

    MultipleSelectionListView {
        id: mlist
        anchors.fill: parent
        cacheBuffer: units.gu(10) * 20
        clip: true
        focus: false
        highlightFollowsCurrentItem: false
        verticalLayoutDirection: ListView.BottomToTop
        visible: enchat.classType != typeEncryptedChatDiscarded

        maximumFlickVelocity: 5000
        flickDeceleration: 2000

        header: Item{ width: 4; height: units.dp(4) }
        footer: Item{ width: 4; height: units.dp(4) }

        onAtYBeginningChanged: if( atYBeginning && contentHeight>height &&
                                   currentDialog != telegramObject.nullDialog ) messages_model.loadMore()

//        displaced: Transition {
//            NumberAnimation { easing.type: Easing.OutCubic; properties: "y"; duration: 300 }
//        }
//        add: Transition {
//            NumberAnimation { easing.type: Easing.OutCubic; properties: "y"; duration: add_anim_disabler.running? 0 : 300 }
//        }

        section.property: "unreaded"
        section.criteria: ViewSection.FullString
        section.delegate: Item {
            width: mlist.width
            height: unread_texts.text.length != 0 && messages_model.hasNewMessage? 30*Devices.density : 0
            clip: true

            Text {
                id: unread_texts
                anchors.centerIn: parent
                font.family: AsemanApp.globalFont.family
                font.pixelSize: 9*Devices.fontDensity
                color: "#333333"
                text: section=="false"? qsTr("New Messages") : ""
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: unread_texts.left
                anchors.margins: 10*Devices.density
                anchors.verticalCenter: parent.verticalCenter
                color: Cutegram.currentTheme.masterColor
                height: 1*Devices.density
            }

            Rectangle {
                anchors.left: unread_texts.right
                anchors.right: parent.right
                anchors.margins: 10*Devices.density
                anchors.verticalCenter: parent.verticalCenter
                color: Cutegram.currentTheme.masterColor
                height: 1*Devices.density
            }
        }

        listModel: messages_model
        listDelegate: MessagesListItem {
            id: message_item
            maximumMediaHeight: acc_msg_list.maximumMediaHeight
            maximumMediaWidth: acc_msg_list.maximumMediaWidth
            message: item
            width: mlist.width
            visibleNames: isChat
            opacity: filterId == user.id || filterId == -1 ? 1 : 0.1

            leftSideActions: [
                Action {
                    iconName: "delete"
                    text: i18n.tr("Delete")
                    onTriggered: telegram.deleteMessages([item.id])
                }
            ]

            rightSideActions: [
                // TODO resend action
                Action {
                    iconName: "edit-copy"
                    text: i18n.tr("Copy")
                    visible: !message_item.hasMedia
                    onTriggered: Clipboard.push(item.message)
                },
                Action {
                    iconName: "next"
                    text: i18n.tr("Forward")
                    //visible: !pageIsSecret
                    onTriggered: forwardMessages([message.id])
                }
            ]

            selected: mlist.isSelected(message_item)
            selectionMode: mlist.isInSelectionMode

            onMessageFocusRequest: focusOnMessage(msgId)

            onItemPressAndHold: {
                mlist.clearSelection();
                mlist.startSelection();
                if (mlist.isInSelectionMode) {
                    mlist.selectItem(message_item);
                }
            }

            onItemClicked: {
                console.log("on item clicked");
                if (mlist.isInSelectionMode) {
                    if (selected) {
                        mlist.deselectItem(message_item);
                    } else {
                        mlist.selectItem(message_item);
                    }
                }

                mouse.accepted = true;
                message_item.click();
            }

            onPreviewRequest: {
                console.log("onOpenMedia");
                var properties;
                switch (type) {
                case FileHandler.TypeTargetMediaPhoto:
                    properties = {
                        "user": user,
                        "photoPreviewSource": path
                    };
                    break;
                case FileHandler.TypeTargetMediaVideo:
                    properties = {
                        "user": user,
                        "videoPreviewSource": path
                    };
                    break;
                case FileHandler.TypeTargetMediaDocument:
                    // TODO export document
                    pageStack.push(picker_page_component, {
                            "url": path,
                            "handler": ContentHandler.Destination,
                            "contentType": ContentType.All
                    });
                    return;
                case FileHandler.TypeTargetMediaAudio:
                    return;
                }
                pageStack.push(preview_page_component, properties);
            }
        }

        Component.onCompleted: {
            // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
            // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
            var scaleFactor = units.gridUnit / 8;
            maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
            flickDeceleration = flickDeceleration * scaleFactor;
        }

    }

    MouseArea {
        anchors.fill: parent
        onPressed: {
            acc_msg_list.focusRequest()
            mouse.accepted = false
        }
    }

    NormalWheelScroll {
        flick: mlist
        animated: Cutegram.smoothScroll
        reverse: true
    }

    PhysicalScrollBar {
        scrollArea: mlist; height: mlist.height-bottomMargin-topMargin; width: 6*Devices.density
        anchors.right: mlist.right; anchors.top: mlist.top; color: textColor0
        anchors.topMargin: topMargin; reverse: true
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: acc_msg_list.topMargin
        anchors.bottomMargin: acc_msg_list.bottomMargin
        clip: true

        Rectangle {
            width: parent.width
            height: 40*Devices.density
            y: selected_list.count==0? -height : 0
            color: currentDialog.encrypted? Cutegram.currentTheme.headerSecretColor : Cutegram.currentTheme.headerColor

            Behavior on y {
                NumberAnimation{easing.type: Easing.OutCubic; duration: 300}
            }

            Row {
                id: toolbutton_row
                anchors.centerIn: parent
                height: parent.height

                property bool toolButtonLightIcon: currentDialog.encrypted? Cutegram.currentTheme.headerSecretLightIcon : Cutegram.currentTheme.headerLightIcon
                property color toolButtonColors: {
                    var mclr = Cutegram.currentTheme.masterColor
                    return Qt.rgba(mclr.r, mclr.g, mclr.b, 0.3)
                }

                Button {
                    width: height
                    height: parent.height
                    icon: toolbutton_row.toolButtonLightIcon? "files/select-none-light.png" : "files/select-none.png"
                    normalColor: "#00000000"
                    highlightColor: toolbutton_row.toolButtonColors
                    iconHeight: 22*Devices.density
                    onClicked: selected_list.clear()
                }

                Button {
                    width: height
                    height: parent.height
                    icon: toolbutton_row.toolButtonLightIcon? "files/forward-light.png" : "files/forward.png"
                    normalColor: "#00000000"
                    highlightColor: toolbutton_row.toolButtonColors
                    iconHeight: 22*Devices.density
                    onClicked: {
                        acc_msg_list.forwardRequest(selected_list.toList())
                        selected_list.clear()
                    }
                }

                Button {
                    width: height
                    height: parent.height
                    icon: "files/delete.png"
                    normalColor: "#00000000"
                    highlightColor: toolbutton_row.toolButtonColors
                    iconHeight: 22*Devices.density
                    onClicked: {
                        var ids = new Array
                        for(var i=0; i<selected_list.count; i++)
                            ids[i] = selected_list.at(i).id

                        telegramObject.deleteMessages(ids)
                        selected_list.clear()
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 2*Devices.density
            opacity: selected_list.count!=0? 0.3 : 0
            gradient: Gradient {
                GradientStop { position: 0.0; color: currentDialog.encrypted? Cutegram.currentTheme.headerSecretTitleColor : Cutegram.currentTheme.headerTitleColor }
                GradientStop { position: 1.0; color: "#00000000" }
            }

            Behavior on opacity {
                NumberAnimation{easing.type: Easing.OutCubic; duration: 300}
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: bottomMargin + 8*Devices.density
        anchors.rightMargin: 8*Devices.density
        width: units.gu(7)//64*Devices.density
        height: width
        radius: height / 2//5*Devices.density
        color: "#88000000"
//        normalColor: "#88000000"
//        highlightColor: "#aa000000"
//        iconSource: "files/down.png"
//        cursorShape: Qt.PointingHandCursor
//        iconHeight: 18*Devices.density
        visible: opacity != 0
        opacity: mlist.visibleArea.yPosition+mlist.visibleArea.heightRatio < 0.95? 1 : 0

        MouseArea {
            anchors.fill: parent
            onClicked: mlist.positionViewAtBeginning()
        }

//        onClicked: mlist.positionViewAtBeginning()

        Image {
            anchors.centerIn: parent
            height: units.gu(2)
            fillMode: Image.PreserveAspectFit
            source: "qrc:/qml/files/down.png"
        }

        Behavior on opacity {
            NumberAnimation{ easing.type: Easing.OutCubic; duration: 300 }
        }
    }

    Label {
        id: acc_rjc_txt
        anchors.top: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: units.gu(5)
        fontSize: "large"
        text: i18n.tr("Secret chat requested.")
        visible: enchat.classType == typeEncryptedChatRequested
        onVisibleChanged: secret_chat_indicator.stop()
    }

    Label {
        id: rejected_txt
        anchors.top: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: units.gu(5)
        fontSize: "x-small"
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("Secret chat rejected or accepted from another device.\nNote that Android accepts secret chats automatically.")
        visible: enchat.classType == typeEncryptedChatDiscarded
        onVisibleChanged: secret_chat_indicator.stop()
    }

    ActivityIndicator {
        id: secret_chat_indicator
        width: units.gu(3)
        height: width
        anchors.top: acc_rjc_txt.bottom
        anchors.topMargin: units.gu(1)
        anchors.horizontalCenter: parent.horizontalCenter

        function start() { running = true; }
        function stop() { running = false; }
    }

    Timer {
        id: focus_msg_timer
        interval: 300
        onTriggered: {
            var idx = msgIndex
            if(msgId)
                idx = messages_model.indexOf(msgId)

            mlist.positionViewAtIndex(idx, ListView.Center)
            msgIndex = 0
            msgId = 0
        }
        property int msgId
        property int msgIndex
    }

    function clearSelection() {
        mlist.clearSelection();
    }

    function selectAll() {
        mlist.selectAll();
    }

    function getSelectedMessageText() {
        var message = "", item;
        for (var i = mlist.selectedItems.count - 1; i >= 0; i--) {
            item = mlist.selectedItems.get(i);
            var text = item.model.item.message;
            if (text.trim().length > 0) {
                message += text + "\n";
            }
        }
        return message;
    }

    function getSelectedMessageIds() {
        var messageIds = [], item;
        for (var i = 0; i < mlist.selectedItems.count; i++) {
            item = mlist.selectedItems.get(i);
            messageIds.push(item.model.item.id);
        }
        return messageIds;
    }

    function copySelected() {
        var message = getSelectedMessageText();
        mlist.endSelection();
        Clipboard.push(message);
    }

    function deleteSelected() {
        var messageIds = getSelectedMessageIds();
        mlist.endSelection();
        telegram.deleteMessages(messageIds);
    }

    function forwardSelected() {
        var messageIds = getSelectedMessageIds();
        mlist.endSelection();
        forwardMessages(messageIds);
    }

    function forwardMessages(messageIds) {
        forwardRequest(messageIds);
        pageStack.pop();
    }

    function sendMessage( txt, inReplyTo ) {
        messages_model.sendMessage(txt, inReplyTo)
    }

    function focusOn(msgId) {
        focus_msg_timer.msgId = msgId
    }

    function focusOnMessage(msgId) {
        var idx = messages_model.indexOf(msgId)
        mlist.positionViewAtIndex(idx, ListView.Center)
    }

    function copy() {
        if(selectedText.length == 0)
            return

        Devices.clipboard = selectedText
    }
}
