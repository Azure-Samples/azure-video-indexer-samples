import { Pivot, PivotItem } from "@fluentui/react";
import DOMPurify from "dompurify";

import styles from "./AnalysisPanel.module.css";

import { SupportingContent } from "../SupportingContent";
import { AskResponse } from "../../api";
import { AnalysisPanelTabs } from "./AnalysisPanelTabs";
import { getFormattedEndTime, getFormattedStartTime, getVideoTitle } from "../../utils/vi-utils";

interface Props {
    className: string;
    activeTab: AnalysisPanelTabs;
    onActiveTabChanged: (tab: AnalysisPanelTabs) => void;
    activeCitation: string | undefined;
    activeScene?: string | undefined;
    citationHeight: string;
    answer: AskResponse;
}

const pivotItemDisabledStyle = { disabled: true, style: { color: "grey" } };

export const AnalysisPanel = ({ answer, activeTab, activeCitation, activeScene, citationHeight, className, onActiveTabChanged }: Props) => {
    const isDisabledThoughtProcessTab: boolean = !answer.thoughts;
    const isDisabledSupportingContentTab: boolean = !answer.data_points.length;
    const isDisabledCitationTab: boolean = !activeCitation;
    const sanitizedThoughts = DOMPurify.sanitize(answer.thoughts!);

    return (
        <Pivot
            className={className}
            selectedKey={activeTab}
            onLinkClick={pivotItem => pivotItem && onActiveTabChanged(pivotItem.props.itemKey! as AnalysisPanelTabs)}
            overflowBehavior="menu"
        >
            <PivotItem
                itemKey={AnalysisPanelTabs.ThoughtProcessTab}
                headerText="Thought process"
                headerButtonProps={isDisabledThoughtProcessTab ? pivotItemDisabledStyle : undefined}
            >
                <div className={styles.thoughtProcess} dangerouslySetInnerHTML={{ __html: sanitizedThoughts }}></div>
            </PivotItem>
            <PivotItem
                itemKey={AnalysisPanelTabs.SupportingContentTab}
                headerText="Supporting content"
                headerButtonProps={isDisabledSupportingContentTab ? pivotItemDisabledStyle : undefined}
            >
                <SupportingContent supportingContent={answer.data_points} answer={answer} />
            </PivotItem>

            <PivotItem
                className={styles.citationTab}
                itemKey={AnalysisPanelTabs.CitationTab}
                headerText="Citation"
                headerButtonProps={isDisabledCitationTab ? pivotItemDisabledStyle : undefined}
            >
                {activeScene ? (
                    <div>
                        <div className={styles.playerContainer}>
                            <iframe
                                className={styles.playerIframe}
                                title="Citation"
                                src={activeCitation}
                                width="100%"
                                height={citationHeight}
                                frameBorder="0"
                                allow="fullscreen"
                            />
                        </div>
                        <h2 className={styles.citationVideoTitle}>{getVideoTitle(activeScene, answer.docs_by_id, false, false)}</h2>
                        <p className={styles.citationVideoTime}>{`${getFormattedStartTime(answer.docs_by_id[activeScene!])} - ${getFormattedEndTime(
                            answer.docs_by_id[activeScene!]
                        )}`}</p>
                    </div>
                ) : null}
            </PivotItem>
        </Pivot>
    );
};
