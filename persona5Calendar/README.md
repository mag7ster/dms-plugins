# Persona 5 Calendar

Layered desktop calendar HUD inspired by *Persona 5* and *Persona 5 Royal* with animated weather.

![preview](screenshot.png)

## Install

Use the DMS CLI:
```bash
dms plugins install persona5Calendar
```

Or manually:
```bash
git clone https://github.com/hthienloc/dms-persona5-calendar ~/.config/DankMaterialShell/plugins/persona5Calendar
```

## Features

- **Layered HUD** - Comic-style date, month, and day-of-week layering
- **Animated Weather** - 3-frame cycling icons synced with DMS `WeatherService`
- **Dynamic Theming** - Auto-switches between P5 Vanilla and P5 Royal palettes
- **Time of Day** - Game schedule or astronomical sun period tracking
- **Holiday Highlighting** - Optional Dux Calendar integration with red holiday dates and working-day exceptions

## Holiday calendars

1. Install and start [Dux Calendar (`dcal`)](https://duxlabs.dev/docs/dcal/installation),
   using a native or Flatpak installation, and connect a holiday calendar for your country or region.
2. Enable **Highlight Holidays** in the widget settings and select **Calendar of Red Dates**.
3. Optionally select a separate **Working Exceptions Calendar** with all-day events on
   transferred working days. These events take priority over holidays.

## Usage

| Action | Result |
|--------|--------|
| Left click | Trigger configured action (refresh weather / show date toast / none) |

## Credits

- **[Mive82](https://github.com/Mive82/Persona-5-Calendar)** — Creator of the original Rainmeter skin
- **[BHDown](https://www.reddit.com/r/Persona5/comments/bjldpg/high_resolution_calendar_assets_and_rainmeter/)** — High-resolution vector assets
- **Dartemil** — Original skin concept

## License

MIT
