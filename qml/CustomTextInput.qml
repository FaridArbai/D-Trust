import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0
import QtQuick.Window 2.3
import QtQuick.Controls.Styles 1.4
import "Constants.js" as Constants


Item{
    id: root
    height: input.height + bottom_line.opened_height + indicator.opened_spacing;

    property bool counter_visible   :   false;
    property int max_chars          :   50;
    property string hint            :   "Type something";

    property real pixelsize         :   10;
    property int echo_mode          :   TextInput.Normal;
    property string text            :   input.text;
    property string initial_text    :   "";


    property string hintColor       :   Constants.TextInput.HINT_COLOR;
    property string textColor       :   Constants.TextInput.TEXT_COLOR;
    property string separatorColor  :   Constants.TextInput.SEPARATOR_COLOR;
    property string focusColor      :   Constants.VIBRANT_COLOR;

    property int bottomPadding      :   0.26*pixelsize;

    property var tabTarget  :   input;
    property alias inputAlias   :   input;


    Component.onCompleted: {
        if(input.text.length==0){
            hint_label.visible = true;
            indicator.font.pixelSize = indicator.closed_pixelsize;
            indicator.visible = false;
        }
        else{
            hint_label.visible = false;
            indicator.font.pixelSize = indicator.opened_pixelsize;
            indicator.visible = true;
            indicator.a = 0;
        }
    }

    TextInput{
        id: input
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width
        bottomPadding: root.bottomPadding
        rightPadding: counter_visible?(2*font.pixelSize):(0)
        font.letterSpacing: (echo_mode==TextInput.Password)?(pixelsize/8):(0)
        echoMode: echo_mode
        passwordCharacter: Constants.TextInput.PASSWORD_CHARACTER
        passwordMaskDelay: Constants.TextInput.MASK_DELAY
        font.pixelSize: pixelsize
        text: root.initial_text
        color: root.textColor
        clip: true
        maximumLength: max_chars
        KeyNavigation.tab: root.tabTarget
        cursorDelegate: CustomCursor{
            pixelSize: root.pixelsize
            visible: input.activeFocus
            color: root.focusColor
        }

        onActiveFocusChanged: {
            if(activeFocus){
                indicator.open();
            }
            else{
                if(input.text.length==0){
                    indicator.close();
                }
            }
        }
    }

    Label{
        id: counter
        bottomPadding: input.bottomPadding
        anchors.right: input.right
        anchors.rightMargin: input.font.pixelSize/2
        anchors.bottom: input.bottom
        font.pixelSize: (7/8)*input.font.pixelSize
        text: max_chars - input.text.length
        color: input.color
        visible: counter_visible
    }

    Label{
        id: hint_label
        bottomPadding: input.bottomPadding
        anchors.bottom: input.bottom
        anchors.left: input.left
        font.pixelSize: input.font.pixelSize
        text: hint
        color: root.hintColor
    }

    Rectangle{
        id: bottom_line
        anchors.bottom: input.bottom
        anchors.bottomMargin: -5
        anchors.left: input.left
        height: input.activeFocus ? opened_height : closed_height
        width: input.width
        color: input.activeFocus ? root.focusColor : root.separatorColor

        property int closed_height  :   (PLATFORM==="ANDROID")?(5*(main.density/3.5)):(1);
        property int opened_height  :   (PLATFORM==="ANDROID")?(7*(main.density/3.5)):(2);
    }

    Label{
        id: indicator
        x: hint_label.x
        y: hint_label.y*a + (hint_label.y - opened_spacing)*b
        font.pixelSize: closed_pixelsize
        color: input.activeFocus ? Qt.tint(root.focusColor, addTransparency(Math.round(a*255), root.hintColor)) : root.hintColor
        text: hint_label.text
        visible: false

        property real a :   1;
        property real b :   1-a;

        property real opened_pixelsize  :   0.74*input.font.pixelSize;
        property real closed_pixelsize  :   hint_label.font.pixelSize;

        property real opened_spacing    :   input.font.pixelSize;

        SequentialAnimation{
            id: open_animation

            PropertyAction{
                target: hint_label
                property: "visible"
                value: false
            }

            PropertyAction{
                target: indicator
                property: "visible"
                value: true
            }

            PropertyAnimation{
                target: indicator
                property: "a"
                to: 0
                duration: 150
            }
        }

        SequentialAnimation{
            id: close_animation

            PropertyAnimation{
                target: indicator
                property: "a"
                to: 1
                duration: 150
            }

            PropertyAction{
                target: indicator
                property: "visible"
                value: false
            }

            PropertyAction{
                target: hint_label
                property: "visible"
                value: true
            }
        }

        PropertyAnimation{
            id: open_font
            target: indicator
            property: "font.pixelSize"
            to: indicator.opened_pixelsize
            duration: 150
            easing.type: Easing.OutQuint
        }

        PropertyAnimation{
            id: close_font
            target: indicator
            property: "font.pixelSize"
            to: indicator.closed_pixelsize
            duration: 150
            easing.type: Easing.InQuint
        }

        function open(){
            open_font.start();
            open_animation.start();
        }

        function close(){
            close_font.start();
            close_animation.start();
        }

        function addTransparency(transparency,color){
            var has_one_character = transparency<=0x0F;
            var transparency_str = (has_one_character?("0"):("")) + transparency.toString(16);
            var final_color = "#" + transparency_str + color.substr(1);

            return final_color;
        }
    }

}
