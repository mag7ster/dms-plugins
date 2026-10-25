pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// A private, read-only IPC client: never changes CalendarService's shared range.
Item {
    id: root

    property bool active: false
    property date today: new Date()
    property string holidayCalendarId: ""
    property string workingCalendarId: ""
    property var calendars: []
    property var events: []
    property string status: "disabled"
    readonly property bool busy: _busy
    readonly property string dateKey: Qt.formatDate(today, "yyyy-MM-dd")
    readonly property string requestKey: JSON.stringify([
        active, dateKey, today.getTimezoneOffset(), holidayCalendarId, workingCalendarId
    ])
    readonly property bool usable: active && (status === "ready" || status === "loading") && _resultKey === requestKey

    property bool _busy: false
    property bool _pending: false
    property bool _complete: false
    property bool _timedOut: false
    property int _generation: 0
    property int _requestGeneration: 0
    property string _resultKey: ""
    property string _stage: ""
    property string _output: ""
    property var _prefix: []
    property var _events: []
    property int _offset: 0
    readonly property int _pageSize: 200

    visible: false

    Component.onCompleted: {
        _complete = true;
        refresh();
    }
    onRequestKeyChanged: if (_complete) refresh()

    function refresh() {
        _generation++;
        // Keep the last result during refresh, but never reuse another day's
        // or another calendar selection's colors.
        if (!active || _resultKey !== requestKey) {
            _resultKey = "";
            events = [];
        }
        _pending = active;
        status = active ? "loading" : "disabled";
        if (!_busy && _pending) Qt.callLater(_begin);
    }

    function _begin() {
        if (_busy || !_pending || !active) return;
        _pending = false;
        _busy = true;
        _requestGeneration = _generation;
        _events = [];
        _offset = 0;
        // Only constant shell syntax; all subsequent IPC arguments are discrete.
        _run("discover", ["sh", "-c", "command -v dcal && exit 0; command -v flatpak >/dev/null 2>&1 || exit 1; for id in dev.duxlabs.calendar com.danklinux.dankcalendar; do if flatpak info \"$id\" >/dev/null 2>&1; then echo \"flatpak:$id\"; exit 0; fi; done; exit 1"]);
    }

    function _run(stage, command) {
        if (!active || _requestGeneration !== _generation) {
            _finish(status);
            return;
        }
        _stage = stage;
        _timedOut = false;
        _output = "";
        process.command = command;
        process.running = true;
        watchdog.restart();
    }

    function _finish(nextStatus) {
        watchdog.stop();
        _busy = false;
        if (_requestGeneration === _generation) {
            if (nextStatus !== "ready" && nextStatus !== "loading") {
                _resultKey = "";
                events = [];
            }
            status = nextStatus;
        }
        if (_pending) Qt.callLater(_begin);
    }

    function _result(text) {
        const response = JSON.parse(text);
        if (response && response.error) throw new Error("IPC error");
        return response && response.result !== undefined ? response.result : response;
    }

    function _loadEvents() {
        // Include UTC date boundaries as well as the local day: dcal serializes
        // all-day events at UTC midnight, regardless of the machine's timezone.
        const d = today;
        const localStart = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        const localEnd = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);
        const utcStart = Date.UTC(d.getFullYear(), d.getMonth(), d.getDate());
        const utcEnd = Date.UTC(d.getFullYear(), d.getMonth(), d.getDate() + 1);
        _run("events", _prefix.concat([
            "ipc", "events.list",
            "from=" + new Date(Math.min(localStart.getTime(), utcStart)).toISOString(),
            "to=" + new Date(Math.max(localEnd.getTime(), utcEnd)).toISOString(),
            "limit=" + _pageSize, "offset=" + _offset
        ]));
    }

    function _receive(exitCode) {
        watchdog.stop();
        if (_requestGeneration !== _generation) {
            _finish(status);
            return;
        }
        if (_timedOut || exitCode !== 0) {
            if (_stage === "discover") calendars = [];
            _finish(_stage === "discover" ? "unavailable" : "error");
            return;
        }
        try {
            if (_stage === "discover") {
                const binary = _output.trim();
                if (!binary) throw new Error("No command");
                _prefix = binary.startsWith("flatpak:")
                    ? ["flatpak", "run", binary.slice(8)] : [binary];
                Qt.callLater(() => _run("calendars", _prefix.concat(["ipc", "calendars.list"])));
                return;
            }
            const result = _result(_output);
            if (_stage === "calendars") {
                if (!Array.isArray(result)) throw new Error("Invalid calendars");
                calendars = result;
                if (!holidayCalendarId) { _finish("choose"); return; }
                if (holidayCalendarId === workingCalendarId) { _finish("conflict"); return; }
                if (!calendars.some(c => c.id === holidayCalendarId)
                        || (workingCalendarId && !calendars.some(c => c.id === workingCalendarId))) {
                    _finish("missing");
                    return;
                }
                Qt.callLater(_loadEvents);
                return;
            }
            if (!result || !Array.isArray(result.events)) throw new Error("Invalid events");
            _events = _events.concat(result.events);
            if (result.events.length >= _pageSize) {
                _offset += result.events.length;
                Qt.callLater(_loadEvents);
                return;
            }
            events = _events;
            _resultKey = requestKey;
            _finish("ready");
        } catch (error) {
            _finish("error");
        }
    }

    Process {
        id: process
        stdout: StdioCollector {
            onStreamFinished: root._output = text
        }
        // Consume diagnostic output without exposing account details in the UI.
        stderr: StdioCollector {}
        onExited: exitCode => root._receive(exitCode)
    }

    Timer {
        id: watchdog
        interval: 20000
        onTriggered: {
            root._timedOut = true;
            if (process.running) process.signal(9);
            else root._finish("error");
        }
    }

    Timer {
        interval: 5 * 60 * 1000
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }
}
