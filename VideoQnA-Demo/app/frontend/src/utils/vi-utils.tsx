import { DocumentsById, VideoDocument } from "../api";
import { getSeconds } from "./time";

const VI_BASE_URL = "https://www.videoindexer.ai/embed/player";
export const getViCitationSrc = (docId: string, docsById: DocumentsById) => {
    const doc = docsById[docId];
    if (!doc) {
        return "";
    }
    const time = getSeconds(doc.start_time);
    const url = `${VI_BASE_URL}/${doc.account_id}/${doc.video_id}?locale=en&location=${doc.location}&t=${time}&captions=en-US&showCaptions=true&boundingBoxes=detectedObjects,people`;
    return url;
};

export const getVideoTitle = (docId: string = "", docsById: DocumentsById, displayStartTime: boolean = true, displayEndTime: boolean = false): string => {
    const doc = docsById[docId];
    if (!doc) {
        return "";
    }
    const startTime = getFormattedStartTime(doc);
    if (displayStartTime && displayEndTime) {
        const endTime = getFormattedEndTime(doc);
        return `${doc.video_name} (${startTime} - ${endTime})`;
    }
    if (displayStartTime) {
        return `${doc.video_name} (${startTime})`;
    }
    return `${doc.video_name}`;
};

export const getFormattedStartTime = (doc: any) => {
    return doc.start_time.split(".")[0];
};
export const getFormattedEndTime = (doc: any) => {
    return doc.end_time.split(".")[0];
};
