.pragma library

// All-day timestamps carry calendar dates in dcal, not local instants.
function eventCoversDate(event, dateKey) {
    if (!event || event.allDay !== true || event.status === "cancelled") return false;
    const start = String(event.start || "").slice(0, 10);
    const end = String(event.end || "").slice(0, 10);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(start)) return false;
    // A missing end denotes a single day. DTEND is otherwise exclusive.
    return end > start ? start <= dateKey && dateKey < end : start === dateKey;
}

function getDayStyle(dayOfWeek, dateKey, events, holidayCalendarId, workingCalendarId) {
    let holiday = false;
    for (const event of events) {
        if (!eventCoversDate(event, dateKey)) continue;
        if (workingCalendarId && event.calendarId === workingCalendarId) return "normal";
        if (holidayCalendarId && event.calendarId === holidayCalendarId) holiday = true;
    }
    if (holiday || dayOfWeek === 0) return "red";
    return dayOfWeek === 6 ? "blue" : "normal";
}

function getWeekTopAsset(version, dayName, style) {
    const base = "assets/Week/" + version + "/";
    if (style === "red" && dayName !== "Sunday") return base + "red/" + dayName + "Top.png";
    if (style === "normal" && (dayName === "Saturday" || dayName === "Sunday"))
        return base + "normal/" + dayName + "Top.png";
    return base + dayName + "Top.png";
}
