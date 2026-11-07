pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Weather from Open-Meteo (open-meteo.com: free, no API key). Location from Config.weather.location via
// Open-Meteo geocoding, or from the IP address via ip-api.com when unset, falling back to Manila.
// Fetches only on demand: when `active` turns on with stale data, and every refreshMinutes while active.
Singleton {
    id: root

    // Set by the dashboard while a tab that shows weather is open.
    property bool active: false
    readonly property bool ready: internal.data !== null
    readonly property string place: internal.place
    readonly property string error: internal.error
    readonly property string unit: Config.weather.units === "imperial" ? "°F" : "°C"
    // Where the forecast is for, once found (Config.weather.location, the IP address, or Manila).
    readonly property bool located: internal.located
    readonly property real latitude: internal.latitude
    readonly property real longitude: internal.longitude
    readonly property real temperature: internal.data?.current.temperature_2m ?? 0
    readonly property real feelsLike: internal.data?.current.apparent_temperature ?? 0
    readonly property int humidity: internal.data?.current.relative_humidity_2m ?? 0
    readonly property int code: internal.data?.current.weather_code ?? 0
    readonly property bool isDay: (internal.data?.current.is_day ?? 1) === 1
    readonly property real high: internal.data?.daily.temperature_2m_max[0] ?? 0
    readonly property real low: internal.data?.daily.temperature_2m_min[0] ?? 0
    readonly property string condition: root.describe(root.code)
    // Next hours as [{ time: "14:00", temperature, code }], starting with the current hour.
    readonly property var hourly: root.nextHours(internal.data, 6)
    readonly property string geocodeUrl: "https://geocoding-api.open-meteo.com/v1/search"
    readonly property string forecastUrl: "https://api.open-meteo.com/v1/forecast"
    // Open-Meteo variable names for the current conditions.
    readonly property string currentFields: root.currentTemperatures + ",relative_humidity_2m,weather_code,is_day"
    readonly property string currentTemperatures: "temperature_2m,apparent_temperature"
    readonly property string hourlyFields: "temperature_2m,weather_code"
    readonly property string dailyFields: "temperature_2m_max,temperature_2m_min"
    // Milliseconds before retrying after an attempt (Open-Meteo answers 503 when overloaded).
    readonly property int retryDelay: 60000
    // Used when the IP lookup fails.
    readonly property var fallback: ({
            name: "Manila",
            lat: 14.5995,
            lon: 120.9842
        })

    function refresh(): void {
        internal.attemptedAt = Date.now();
        internal.error = "";
        const location = Config.weather.location.trim();
        if (location === "")
            root.locateByIp();
        else
            root.geocode(location);
    }

    // Opening the dashboard calls this; without data every open would fetch, so a failed attempt
    // waits retryDelay before the next one (rapid toggling once sent a request per toggle).
    function refreshIfStale(): void {
        const stale = Date.now() - internal.fetchedAt > Config.weather.refreshMinutes * 60000;
        const resting = Date.now() - internal.attemptedAt < root.retryDelay;
        if (stale && !resting)
            root.refresh();
    }

    // No key and no account; the free tier is HTTP only. Any failure falls back to Manila.
    function locateByIp(): void {
        const useFallback = () => root.fetch(root.fallback.name, root.fallback.lat, root.fallback.lon);
        root.get("http://ip-api.com/json?fields=status,city,lat,lon", json => {
            if (json.status === "success")
                root.fetch(json.city, json.lat, json.lon);
            else
                useFallback();
        }, useFallback);
    }

    function geocode(location: string): void {
        root.get(`${root.geocodeUrl}?count=1&format=json&name=${encodeURIComponent(location)}`, json => {
            const hit = json.results?.[0];
            if (hit)
                root.fetch(hit.name, hit.latitude, hit.longitude);
            else
                internal.error = `No place called ${location}`;
        }, null);
    }

    function fetch(place: string, lat: real, lon: real): void {
        const unit = Config.weather.units === "imperial" ? "&temperature_unit=fahrenheit" : "";
        const fields = `current=${root.currentFields}&hourly=${root.hourlyFields}&daily=${root.dailyFields}`;
        const query = `latitude=${lat}&longitude=${lon}&${fields}&timezone=auto&forecast_days=2${unit}`;
        root.get(`${root.forecastUrl}?${query}`, json => {
            internal.latitude = lat;
            internal.longitude = lon;
            internal.located = true;
            internal.place = place;
            internal.data = json;
            internal.fetchedAt = Date.now();
        }, null);
    }

    function get(url: string, done: var, failed: var): void {
        const request = new XMLHttpRequest();
        request.onreadystatechange = () => {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            try {
                if (request.status !== 200)
                    throw new Error(`HTTP ${request.status}`);
                done(JSON.parse(request.responseText));
            } catch (e) {
                internal.error = `${e.message}`;
                console.warn(`[weather] ${url.split("?")[0]}: ${e.message}`);
                failed?.();
            }
        };
        request.open("GET", url);
        request.send();
    }

    function nextHours(data: var, count: int): var {
        if (!data)
            return [];
        const now = data.current.time.slice(0, 13);
        const start = Math.max(0, data.hourly.time.findIndex(t => t.slice(0, 13) === now));
        const hour = i => ({
                    time: data.hourly.time[i].slice(11, 16),
                    temperature: data.hourly.temperature_2m[i],
                    code: data.hourly.weather_code[i]
                });
        return Array.from({
            length: Math.min(count, data.hourly.time.length - start)
        }, (_, i) => hour(start + i));
    }

    function describeHour(hour: var): string {
        return `${hour.time} ${Math.round(hour.temperature)}${root.unit} ${root.describe(hour.code)}`;
    }

    // WMO weather interpretation codes, as Open-Meteo reports them.
    function describe(code: int): string {
        if (code === 0)
            return "Clear";
        if (code <= 2)
            return "Partly cloudy";
        if (code === 3)
            return "Overcast";
        if (code <= 48)
            return "Fog";
        if (code <= 57)
            return "Drizzle";
        if (code <= 67 || (code >= 80 && code <= 82))
            return "Rain";
        if (code <= 77 || code === 85 || code === 86)
            return "Snow";
        return "Thunderstorm";
    }

    function status(): string {
        if (!root.ready)
            return root.error !== "" ? `error: ${root.error}` : "no data yet";
        const t = n => `${Math.round(n)}${root.unit}`;
        const range = `H ${t(root.high)} L ${t(root.low)}`;
        return `${root.place}: ${t(root.temperature)} ${root.condition}, ${range}, ${root.humidity}% humidity`;
    }

    onActiveChanged: {
        if (root.active)
            root.refreshIfStale();
    }

    QtObject {
        id: internal

        property var data: null
        property string place: ""
        property string error: ""
        property real fetchedAt: 0
        property real attemptedAt: 0
        property bool located: false
        property real latitude: 0
        property real longitude: 0
    }

    Timer {
        interval: Config.weather.refreshMinutes * 60000
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        function refresh(): void {
            root.refresh();
        }

        function status(): string {
            return root.status();
        }

        function hourly(): string {
            return root.hourly.map(root.describeHour).join("\n");
        }

        target: "weather"
    }
}
