pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "./shared"
import "./holidays" as Calendar

PluginSettings {
    id: root
    pluginId: "persona5Calendar"

    SystemClock {
        id: calendarClock
        precision: SystemClock.Minutes
    }

    Calendar.HolidayCalendar {
        id: holidays
        active: holidayEnabled.value
        today: calendarClock.date
        holidayCalendarId: holidayCalendar.value
        workingCalendarId: workingCalendar.value
    }

    function calendarOptions(selectedId, excludedId) {
        const options = [{label: I18n.trFor("persona5Calendar", "None"), value: ""}];
        const labels = holidays.calendars.map(c => I18n.trFor("persona5Calendar", "%1 (%2)")
            .arg(c.name || c.id).arg(c.accountName || c.accountId || c.id));
        for (let i = 0; i < holidays.calendars.length; i++) {
            const calendar = holidays.calendars[i];
            if (calendar.id === excludedId && calendar.id !== selectedId) continue;
            const label = labels.indexOf(labels[i]) !== labels.lastIndexOf(labels[i])
                ? I18n.trFor("persona5Calendar", "%1 [%2]").arg(labels[i]).arg(calendar.id) : labels[i];
            options.push({label: label, value: calendar.id});
        }
        if (selectedId && !holidays.calendars.some(c => c.id === selectedId))
            options.push({label: I18n.trFor("persona5Calendar", "Unavailable calendar (%1)").arg(selectedId), value: selectedId});
        return options;
    }

    readonly property string holidayStatusText: {
        switch (holidays.status) {
        case "disabled": return I18n.trFor("persona5Calendar", "Calendar highlighting is disabled.");
        case "loading": return I18n.trFor("persona5Calendar", "Reading calendars…");
        case "unavailable": return I18n.trFor("persona5Calendar", "Install Dux Calendar (dcal) to enable holiday highlighting.");
        case "choose": return I18n.trFor("persona5Calendar", "Choose a calendar of red dates.");
        case "conflict": return I18n.trFor("persona5Calendar", "Choose different calendars for red dates and working exceptions.");
        case "missing": return I18n.trFor("persona5Calendar", "A selected calendar is unavailable. Choose it again.");
        case "ready": return I18n.trFor("persona5Calendar", "Connected to Dux Calendar. Updated every five minutes.");
        default: return I18n.trFor("persona5Calendar", "Cannot read calendars. Start dcal and try again. Using the original weekday colors.");
        }
    }

    SettingsCard {
        id: appearanceSection

        SectionTitle {
            text: I18n.trFor("persona5Calendar", "Appearance")
            icon: "palette"
            showReset: themeVersion.isDirty || widgetOpacity.isDirty
            onResetClicked: {
                themeVersion.resetToDefault();
                widgetOpacity.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: themeVersion
            settingKey: "themeVersion"
            label: I18n.trFor("persona5Calendar", "Theme Palette")
            description: I18n.trFor("persona5Calendar", "Choose standard Persona 5 (Vanilla), Persona 5 Royal, or Dynamic (auto-switches to Royal in Jan & Feb).")
            defaultValue: "dynamic"
            options: [
                { label: I18n.trFor("persona5Calendar", "Dynamic (Vanilla, Royal in Jan/Feb)"), value: "dynamic" },
                { label: I18n.trFor("persona5Calendar", "Vanilla (Persona 5)"), value: "vanilla" },
                { label: I18n.trFor("persona5Calendar", "Royal (Persona 5 Royal)"), value: "royal" }
            ]
        }

        Separator {}

        SliderSettingPlus {
            id: widgetOpacity
            settingKey: "widgetOpacity"
            label: I18n.trFor("persona5Calendar", "Widget Opacity")
            description: I18n.trFor("persona5Calendar", "Adjust transparency of the calendar HUD.")
            defaultValue: 100
            minimum: 20
            maximum: 100
            unit: "%"
            leftLabel: "20%"
            rightLabel: "100%"
        }
    }

    SettingsCard {
        id: weatherSection

        SectionTitle {
            text: I18n.trFor("persona5Calendar", "Time & Weather")
            icon: "wb_sunny"
            showReset: todMode.isDirty || showWeather.isDirty || animateWeather.isDirty || animInterval.isDirty
            onResetClicked: {
                todMode.resetToDefault();
                showWeather.resetToDefault();
                animateWeather.resetToDefault();
                animInterval.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: todMode
            settingKey: "todMode"
            label: I18n.trFor("persona5Calendar", "Time of Day Logic")
            description: I18n.trFor("persona5Calendar", "Calculate time periods using Persona 5 game schedule or local solar calculations via DMS WeatherService.")
            defaultValue: "game"
            options: [
                { label: I18n.trFor("persona5Calendar", "Persona 5 Game Schedule"), value: "game" },
                { label: I18n.trFor("persona5Calendar", "Solar Schedule (Sun Times)"), value: "solar" }
            ]
        }

        Separator {}

        ToggleSettingPlus {
            id: showWeather
            settingKey: "showWeather"
            label: I18n.trFor("persona5Calendar", "Display Weather Icon")
            description: I18n.trFor("persona5Calendar", "Show current weather condition integrated with DMS WeatherService.")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: animateWeather
            settingKey: "animateWeather"
            label: I18n.trFor("persona5Calendar", "Animate Weather")
            description: I18n.trFor("persona5Calendar", "Cycle weather icon frames for game-authentic animation.")
            defaultValue: true
            enabled: showWeather.value
        }

        Separator {}

        SliderSettingPlus {
            id: animInterval
            settingKey: "animInterval"
            label: I18n.trFor("persona5Calendar", "Animation Speed")
            description: I18n.trFor("persona5Calendar", "Interval between weather animation frames (lower is faster).")
            defaultValue: 300
            minimum: 150
            maximum: 800
            unit: "ms"
            leftLabel: "150ms"
            rightLabel: "800ms"
            enabled: showWeather.value && animateWeather.value
        }
    }

    SettingsCard {
        id: interactionSection

        SectionTitle {
            text: I18n.trFor("persona5Calendar", "Interactions")
            icon: "touch_app"
            showReset: clickAction.isDirty
            onResetClicked: {
                clickAction.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: clickAction
            settingKey: "clickAction"
            label: I18n.trFor("persona5Calendar", "Click Action")
            description: I18n.trFor("persona5Calendar", "Action triggered when clicking anywhere on the calendar.")
            defaultValue: "refresh"
            options: [
                { label: I18n.trFor("persona5Calendar", "Force Refresh Weather"), value: "refresh" },
                { label: I18n.trFor("persona5Calendar", "Show Date & Weather Toast"), value: "dateInfo" },
                { label: I18n.trFor("persona5Calendar", "None"), value: "none" }
            ]
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.trFor("persona5Calendar", "Holiday Calendar Guide")
            icon: "help"
        }
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeMedium
            text: I18n.trFor("persona5Calendar", "Connect a holiday calendar in Dux Calendar, then select it below. All-day events turn dates red. A separate working exceptions calendar takes priority.")
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.trFor("persona5Calendar", "Holidays")
            icon: "event"
            showReset: holidayEnabled.isDirty || holidayCalendar.isDirty || workingCalendar.isDirty
            onResetClicked: {
                holidayEnabled.resetToDefault();
                holidayCalendar.resetToDefault();
                workingCalendar.resetToDefault();
            }
        }
        ToggleSettingPlus {
            id: holidayEnabled
            settingKey: "holidayHighlightEnabled"
            label: I18n.trFor("persona5Calendar", "Highlight Holidays")
            defaultValue: false
        }
        Calendar.CalendarSelection {
            id: holidayCalendar
            settings: root
            settingKey: "holidayCalendarId"
            label: I18n.trFor("persona5Calendar", "Calendar of Red Dates")
            options: root.calendarOptions(value, workingCalendar.value)
            enabled: holidayEnabled.value
        }
        Calendar.CalendarSelection {
            id: workingCalendar
            settings: root
            settingKey: "workingCalendarId"
            label: I18n.trFor("persona5Calendar", "Working Exceptions Calendar")
            description: I18n.trFor("persona5Calendar", "Optional. All-day events make the date use ordinary weekday colors, including working Saturdays and Sundays.")
            options: root.calendarOptions(value, holidayCalendar.value)
            enabled: holidayEnabled.value
        }
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeMedium
            text: root.holidayStatusText
        }
        DButton {
            text: I18n.trFor("persona5Calendar", "Refresh Calendars")
            iconName: "refresh"
            busy: holidays.busy
            enabled: holidayEnabled.value && !holidays.busy
            onClicked: {
                holidays.refresh();
                PluginService.setGlobalVar("persona5Calendar", "holidayRefresh", Date.now());
            }
        }
    }

    SettingsCard {
        id: creditsSection

        SectionTitle {
            id: creditsTitle
            text: I18n.trFor("persona5Calendar", "Credits")
            icon: "favorite"
            collapsible: true
            settingKey: "creditsExpanded"
        }

        CreditsList {
            expanded: creditsTitle.isExpanded
            items: [
                {
                    author: "Mive82",
                    url: "https://github.com/Mive82/Persona-5-Calendar",
                    role: I18n.trFor("persona5Calendar", "Creator of the original Persona 5 Rainmeter skin"),
                    icon: "code"
                },
                {
                    author: "BHDown",
                    url: "https://www.reddit.com/r/Persona5/comments/bjldpg/high_resolution_calendar_assets_and_rainmeter/",
                    role: I18n.trFor("persona5Calendar", "High-resolution calendar vector graphics and assets"),
                    icon: "brush"
                },
                {
                    author: "Dartemil",
                    url: "https://www.deviantart.com/dartemil",
                    role: I18n.trFor("persona5Calendar", "Original Persona 5 Calendar skin concept"),
                    icon: "palette"
                }
            ]
        }
    }
}
