(function () {
    "use strict";

    var holdTimer = null;
    var pickerOpen = false;
    var quickSwitchPending = false;

    function send(name, payload) {
        if (typeof safari !== "undefined" && safari.extension && safari.extension.dispatchMessage) {
            safari.extension.dispatchMessage(name, payload || {});
        }
    }

    function clearHoldTimer() {
        if (holdTimer !== null) {
            clearTimeout(holdTimer);
            holdTimer = null;
        }
    }

    document.addEventListener(
        "keydown",
        function (event) {
            if (event.key !== "Tab" || !event.ctrlKey || event.metaKey || event.altKey) {
                return;
            }

            event.preventDefault();
            event.stopImmediatePropagation();

            if (pickerOpen) {
                send("pickerStep", { backward: event.shiftKey });
                return;
            }

            if (event.repeat) {
                return;
            }

            quickSwitchPending = true;
            clearHoldTimer();
            holdTimer = setTimeout(function () {
                quickSwitchPending = false;
                pickerOpen = true;
                send("pickerOpen", { backward: event.shiftKey });
            }, 180);
        },
        true
    );

    document.addEventListener(
        "keyup",
        function (event) {
            if (event.key !== "Control") {
                return;
            }

            clearHoldTimer();

            if (pickerOpen) {
                send("pickerCommit", {});
                pickerOpen = false;
                return;
            }

            if (quickSwitchPending) {
                quickSwitchPending = false;
                send("quickSwitch", {});
            }
        },
        true
    );
})();
