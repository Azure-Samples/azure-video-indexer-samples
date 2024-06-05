import { getVideoTitle } from "./../../utils/vi-utils";
import { AskResponse } from "../../api";

type ParsedSupportingContentItem = {
    title: string;
    content: string;
};

export function parseSupportingContentItem(item: string, answer: AskResponse): ParsedSupportingContentItem {
    // Assumes the item starts with the file name followed by : and the content.
    // Example: "sdp_corporate.pdf: this is the content that follows".
    const parts = item.split(": ");
    const title = getVideoTitle(parts[0], answer.docs_by_id, true, true);
    const content = formatString(parts.slice(1).join(": "));

    return {
        title,
        content
    };
}
// Define a type for the segment keys
type SegmentKey = "Video title" | "Tag" | "Known people" | "Audio effects" | "Visual" | "Transcript" | "OCR" | "Detected objects" | "Description tags" | "Visual labels" | "Tags";

// Define a function that takes a non-formatted string and returns a formatted string
function formatString(input: string): string {
    // Initialize an empty output string
    let output = "";

    // Split the input by the segment keys using a regular expression
    let segments = input.split(/(\[Video title\]|\[Tag\]|\[Tags\]|\[Detected objects\]|\[Description tags\]|\[Known people\]|\[Audio effects\]|\[Visual\]|\[Visual labels\]|\[OCR\]|\[Transcript\])/);

    // Loop through the segments array, skipping the first empty element
    for (let i = 1; i < segments.length; i += 2) {
        // Get the segment key and value
        let key = segments[i].substring(1, segments[i].length - 1) as SegmentKey;
        // take the substring of the key to remove the brackets
        let value = segments[i + 1];

        // Trim the value of any leading or trailing whitespace
        value = value.trim();

        // Add the segment key and value to the output string with newlines
        output += `${key}:\n${value}\n\n`;
    }

    // Return the output string
    return output;
}
