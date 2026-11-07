pragma Singleton

import Quickshell

// Sunrise and sunset from the sunrise equation (NOAA's simplified form; within a minute or two away from
// the poles). Pure: no network, no clock of its own.
Singleton {
    id: root

    readonly property real rad: Math.PI / 180
    // The Sun's disc and refraction: it rises when its centre is this far below the horizon.
    readonly property real horizon: -0.833
    readonly property real obliquity: 23.4397

    // { sunrise, sunset } as Dates for the day of `date` (pass local noon, so the day is unambiguous), at
    // latitude/longitude in degrees (east positive). Both are null when the Sun doesn't rise or set that
    // day (polar day or night).
    function times(date: date, latitude: real, longitude: real): var {
        const julianDate = date.getTime() / 86400000 + 2440587.5;
        const days = Math.round(julianDate - 2451545 + 0.0008) - longitude / 360;
        const anomaly = (357.5291 + 0.98560028 * days) % 360;
        const m = anomaly * root.rad;
        const centre = 1.9148 * Math.sin(m) + 0.02 * Math.sin(2 * m) + 0.0003 * Math.sin(3 * m);
        const ecliptic = ((anomaly + centre + 180 + 102.9372) % 360) * root.rad;
        const transit = 2451545 + days + 0.0053 * Math.sin(m) - 0.0069 * Math.sin(2 * ecliptic);
        const declination = Math.asin(Math.sin(ecliptic) * Math.sin(root.obliquity * root.rad));
        const phi = latitude * root.rad;
        const above = Math.sin(root.horizon * root.rad) - Math.sin(phi) * Math.sin(declination);
        const cosHour = above / (Math.cos(phi) * Math.cos(declination));
        if (cosHour > 1 || cosHour < -1)
            return {
                sunrise: null,
                sunset: null
            };
        const hour = Math.acos(cosHour) / root.rad / 360;
        const toDate = julian => new Date((julian - 2440587.5) * 86400000);
        return {
            sunrise: toDate(transit - hour),
            sunset: toDate(transit + hour)
        };
    }
}
