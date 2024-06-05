import { parseSupportingContentItem } from "./SupportingContentParser";

import styles from "./SupportingContent.module.css";
import { AskResponse } from "../../api";

interface Props {
    supportingContent: string[];
    answer: AskResponse;
}

export const SupportingContent = ({ supportingContent, answer }: Props) => {
    return (
        <ul className={styles.supportingContentNavList}>
            {supportingContent.map((x, i) => {
                const parsed = parseSupportingContentItem(x, answer);

                return (
                    <li className={styles.supportingContentItem}>
                        <h4 className={styles.supportingContentItemHeader}>{parsed.title}</h4>
                        <pre className={styles.supportingContentItemText}>{parsed.content}</pre>
                    </li>
                );
            })}
        </ul>
    );
};
