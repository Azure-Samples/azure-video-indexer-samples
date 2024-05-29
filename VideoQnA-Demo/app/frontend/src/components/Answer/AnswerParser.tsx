import { renderToStaticMarkup } from "react-dom/server";
import { getViCitationSrc, getVideoTitle } from "../../utils/vi-utils";
import { AskResponse } from "../../api";

type HtmlParsedAnswer = {
    answerHtml: string;
    citations: string[];
    followupQuestions: string[];
};

export function parseAnswerToHtml(answer: AskResponse): HtmlParsedAnswer {
    const citations: string[] = [];
    const followupQuestions: string[] = [];

    // Extract any follow-up questions that might be in the answer
    let parsedAnswer = answer.answer.replace(/<<([^>>]+)>>/g, (match, content) => {
        followupQuestions.push(content);
        return "";
    });

    // trim any whitespace from the end of the answer after removing follow-up questions
    parsedAnswer = parsedAnswer.trim();

    const parts = parsedAnswer.split(/\[([^\]]+)\]/g);

    const fragments: string[] = parts.map((part, index) => {
        if (index % 2 === 0) {
            return part;
        } else {
            let citationIndex: number;
            if (citations.indexOf(part) !== -1) {
                citationIndex = citations.indexOf(part) + 1;
            } else {
                citations.push(part);
                citationIndex = citations.length;
            }

            const path = getViCitationSrc(part, answer.docs_by_id);
            const title = getVideoTitle(part, answer.docs_by_id);
            return renderToStaticMarkup(
                <a className="supContainer" title={title}>
                    <sup data-docid={part} data-path={path}>
                        {citationIndex}
                    </sup>
                </a>
            );
        }
    });

    return {
        answerHtml: fragments.join(""),
        citations,
        followupQuestions
    };
}
