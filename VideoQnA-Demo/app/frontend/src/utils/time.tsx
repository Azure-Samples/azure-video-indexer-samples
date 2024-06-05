const DAYS_PER_MONTH: number = 146097 / 400 / 12;
const SECONDS_PER_HOUR: number = 60 * 60;
const SECONDS_PER_MINUTE: number = 60;
export const formattedStartTime = "00:00:00";

export interface IDurationDetails {
    number: number;
    units: string;
}

export enum TimeInterval {
    MINUTE = 60 * 1000,
    SECOND = 1000,
    HOUR = 60 * 60 * 1000,
    DAY = 24 * 60 * 60 * 1000,
    YEAR = 365 * 24 * 60 * 60 * 1000
}

export function getSeconds(hms: string | number): number {
    if (typeof hms === "number") {
        return hms;
    }

    const time = formatToStandardTime(hms);
    const timeSplit = time.split(":");
    const hours = +timeSplit[0];
    const minutes = +timeSplit[1];
    const seconds = +timeSplit[2];

    return hours * SECONDS_PER_HOUR + minutes * SECONDS_PER_MINUTE + seconds;
}

export function getTimeText(time: string): string {
    return time && time.split(".")[0];
}

export function formatToStandardTime(time: string | number, padMilliSeconds = false, padNum = 3): string {
    if (typeof time === "number") {
        time = toTimeText(time);
    }

    time = time?.toString();
    const displayTime = time?.split(".");

    if (!displayTime || !displayTime[0]) {
        return "";
    }
    const timeSplit = displayTime[0]?.split(":");
    const hours = timeSplit[0]?.padStart(2, "0");
    const minutes = timeSplit[1]?.padStart(2, "0");
    const seconds = timeSplit[2]?.padStart(2, "0");
    const milliseconds =
        displayTime[1] && !isNaN(displayTime[1] as unknown as number)
            ? "." + `${+displayTime[1] / Math.pow(10, displayTime[1]?.length)}`?.split(".")[1]?.padEnd(padNum, "0")
            : padMilliSeconds
            ? ".".padEnd(padNum + 1, "0")
            : "";

    return hours + ":" + minutes + ":" + seconds + milliseconds;
}

export function toTimeText(time: number, roundSeconds = false): string {
    const sec_num = time; // don't forget the second param
    let hours: number | string = Math.floor(sec_num / 3600);
    let minutes: number | string = Math.floor((sec_num - hours * 3600) / 60);
    let seconds: number | string = sec_num - hours * 3600 - minutes * 60;
    if (roundSeconds) {
        seconds = Math.round(seconds);
    }
    if (seconds === 60) {
        seconds = 0;
        minutes++;
        if (minutes === 60) {
            minutes = 0;
            hours++;
        }
    }

    if (hours < 10) {
        hours = "0" + hours;
    }
    if (minutes < 10) {
        minutes = "0" + minutes;
    }
    if (seconds < 10) {
        seconds = "0" + seconds;
    }
    return hours + ":" + minutes + ":" + seconds;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function humanize(duration: any): IDurationDetails | null {
    let ago = duration < 0;
    duration = Math.abs(duration);
    duration = [
        { n: thresh(45, duration / 1000), units: "Seconds" },
        { n: thresh(45, duration / (60 * 1000)), units: "Minutes" },
        { n: thresh(22, duration / (60 * 60 * 1000)), units: "Hours" },
        { n: thresh(26, duration / (24 * 60 * 60 * 1000)), units: "Days" },
        { n: thresh(11, duration / (DAYS_PER_MONTH * 24 * 60 * 60 * 1000)), units: "Months" },
        { n: thresh(Number.MAX_VALUE, duration / (365 * 24 * 60 * 60 * 1000)), units: "Years" },
        { n: "Now", units: "Now" }
    ];

    duration = first(duration, (part: any) => {
        return part.n !== 0;
    });
    ago = ago && duration.n !== "Now";
    if (duration.n === 1) {
        duration.units = duration.units.replace(/s$/, "");
    }

    return duration
        ? {
              number: duration.n,
              units: duration.units
          }
        : null;
}

export function humanizeFromNow(date: Date | string): IDurationDetails | null {
    return humanize(fromNow(date));
}

export function fromNow(date: Date | string) {
    if (!(date instanceof Date)) {
        date = new Date(date);
    }

    const now = new Date();
    return getUTCDate(date).valueOf() - getUTCDate(now).valueOf();
}

export function getUTCDate(date: Date) {
    return new Date(date.getTime() + date.getTimezoneOffset() * 60000);
}

export function isOverTimeOffset(timeForCheck: number, timeOffset: number) {
    return new Date(timeForCheck).getTime() < new Date().getTime() - timeOffset;
}

// if it is in the current day returns time, before returns the date in format DD/MM/YY
export function getDateString(startDate: Date) {
    if (new Date().getTime() - startDate.getTime() < TimeInterval.DAY) {
        return startDate.toLocaleTimeString(navigator.language, { hour: "numeric", minute: "numeric" });
    } else {
        return `${startDate.getDate()}/${startDate.getMonth() + 1}/${startDate?.getFullYear().toString().substring(2, 4)}`;
    }
}

export function toLocaleString(
    date: Date,
    locale: string = "en-US",
    options: Intl.DateTimeFormatOptions = { hour: "numeric", minute: "numeric", hour12: true }
) {
    return date.toLocaleString(locale, options);
}

export function toLocaleDateString(date: Date, locale: string = "en-US", options: Intl.DateTimeFormatOptions = {}) {
    return date.toLocaleDateString(locale, options);
}

function thresh(t: number, val: number): number {
    val = Math.round(val);

    return val < t ? val : 0;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function first(arr: any, func: Function): string {
    for (const item of arr) {
        if (func(item)) {
            return item;
        }
    }
    return "";
}
