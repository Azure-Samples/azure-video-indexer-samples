import { useRef, useState, useEffect } from "react";
import { Checkbox, ChoiceGroup, IChoiceGroupOption, Panel, DefaultButton, Spinner, TextField, SpinButton, IDropdownOption } from "@fluentui/react";

import styles from "./OneShot.module.css";

import { askApi, Approaches, AskResponse, AskRequest, indexesAPI } from "../../api";
import { Answer, AnswerError } from "../../components/Answer";
import { QuestionInput } from "../../components/QuestionInput";
import { ExampleList } from "../../components/Example";
import { IndexesDropdown } from "../../components/IndexesDropdown";
import { AnalysisPanel, AnalysisPanelTabs } from "../../components/AnalysisPanel";
import { SettingsButton } from "../../components/SettingsButton/SettingsButton";
import { ClearChatButton } from "../../components/ClearChatButton";

const OneShot = () => {
    const [isConfigPanelOpen, setIsConfigPanelOpen] = useState(false);
    const [approach, setApproach] = useState<Approaches>(Approaches.ReadRetrieveReadVector);
    const [promptTemplate, setPromptTemplate] = useState<string>("");
    const [promptTemplatePrefix, setPromptTemplatePrefix] = useState<string>("");
    const [promptTemplateSuffix, setPromptTemplateSuffix] = useState<string>("");
    const [retrieveCount, setRetrieveCount] = useState<number>(3);
    const [useSemanticRanker, setUseSemanticRanker] = useState<boolean>(true);
    const [index, setIndex] = useState<string>();
    const [useSemanticCaptions, setUseSemanticCaptions] = useState<boolean>(false);
    const [excludeCategory, setExcludeCategory] = useState<string>("");

    const lastQuestionRef = useRef<string>("");

    const [isAskLoading, setIsAskLoading] = useState<boolean>(false);
    const [isLoading, setIsLoading] = useState<boolean>(false);
    const [error, setError] = useState<unknown>();
    const [answer, setAnswer] = useState<AskResponse>();
    const [indexes, setIndexes] = useState<IDropdownOption[]>([]);

    const [activeCitation, setActiveCitation] = useState<string>();
    const [activeScene, setActiveScene] = useState<string>();
    const [question, setQuestion] = useState<string>();
    const [activeAnalysisPanelTab, setActiveAnalysisPanelTab] = useState<AnalysisPanelTabs | undefined>(undefined);

    //call getIndexes() on load
    useEffect(() => {
        getIndexes();
    }, []);
    const onIndexChanged = (index: string) => {
        console.log("index changed to: " + index);
        setIndex(index);
    };
    const getIndexes = async () => {
        setIsLoading(true);
        try {
            const indexes = await indexesAPI();
            const convertedIndexes = indexes.map(index => ({ key: index, text: formatString(index) }));
            setIndexes(convertedIndexes);
            if (indexes.includes("vi-prompt-content-example-index")) {
                setIndex("vi-prompt-content-example-index");
            } else {
                setIndex(convertedIndexes[0].key);
            }
        } catch (error) {
            console.error(`Error when getting indexes: ${error}`);
        } finally {
            setIsLoading(false);
        }
    };

    const formatString = (input: string): string => {
        // Split the input by the hyphen character and store the resulting array
        const parts = input.split("-");
        // Initialize an empty array to store the formatted parts
        const formattedParts: string[] = [];
        // Loop through the parts array
        for (const part of parts) {
            // If the part is not empty and not equal to "vi", capitalize the first letter and push it to the formatted parts array
            if (part && part !== "vi") {
                formattedParts.push(part[0].toUpperCase() + part.slice(1));
            }
        }
        // Join the formatted parts array by a space and return the resulting string
        return formattedParts.join(" ");
    };

    const makeApiRequest = async (question: string) => {
        lastQuestionRef.current = question;

        error && setError(undefined);
        setIsAskLoading(true);
        setActiveCitation(undefined);
        setActiveScene(undefined);
        setActiveAnalysisPanelTab(undefined);

        try {
            const request: AskRequest = {
                question,
                approach,
                overrides: {
                    promptTemplate: promptTemplate.length === 0 ? undefined : promptTemplate,
                    promptTemplatePrefix: promptTemplatePrefix.length === 0 ? undefined : promptTemplatePrefix,
                    promptTemplateSuffix: promptTemplateSuffix.length === 0 ? undefined : promptTemplateSuffix,
                    excludeCategory: excludeCategory.length === 0 ? undefined : excludeCategory,
                    top: retrieveCount,
                    index,
                    semanticRanker: useSemanticRanker,
                    semanticCaptions: useSemanticCaptions
                }
            };
            const result = await askApi(request);
            setAnswer(result);
        } catch (e) {
            setError(e);
        } finally {
            setIsAskLoading(false);
        }
    };

    const onPromptTemplateChange = (_ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>, newValue?: string) => {
        setPromptTemplate(newValue || "");
    };

    const onPromptTemplatePrefixChange = (_ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>, newValue?: string) => {
        setPromptTemplatePrefix(newValue || "");
    };

    const onPromptTemplateSuffixChange = (_ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>, newValue?: string) => {
        setPromptTemplateSuffix(newValue || "");
    };

    const onRetrieveCountChange = (_ev?: React.SyntheticEvent<HTMLElement, Event>, newValue?: string) => {
        setRetrieveCount(parseInt(newValue || "3"));
    };

    const onApproachChange = (_ev?: React.FormEvent<HTMLElement | HTMLInputElement>, option?: IChoiceGroupOption) => {
        setApproach((option?.key as Approaches) || Approaches.ReadRetrieveReadVector);
    };

    const onUseSemanticRankerChange = (_ev?: React.FormEvent<HTMLElement | HTMLInputElement>, checked?: boolean) => {
        setUseSemanticRanker(!!checked);
    };

    const onUseSemanticCaptionsChange = (_ev?: React.FormEvent<HTMLElement | HTMLInputElement>, checked?: boolean) => {
        setUseSemanticCaptions(!!checked);
    };

    const onExcludeCategoryChanged = (_ev?: React.FormEvent, newValue?: string) => {
        setExcludeCategory(newValue || "");
    };

    const onExampleClicked = (example: string) => {
        makeApiRequest(example);
        setQuestion(example);
    };

    const onShowCitation = (citation: string, docId: string) => {
        if (activeCitation === citation && activeAnalysisPanelTab === AnalysisPanelTabs.CitationTab) {
            setActiveAnalysisPanelTab(undefined);
        } else {
            setActiveCitation(citation);
            setActiveScene(docId);
            setActiveAnalysisPanelTab(AnalysisPanelTabs.CitationTab);
        }
    };

    const clearChat = () => {
        lastQuestionRef.current = "";
        error && setError(undefined);
        setActiveCitation(undefined);
        setActiveAnalysisPanelTab(undefined);
        setAnswer(undefined);
        setQuestion("");
    };

    const onToggleTab = (tab: AnalysisPanelTabs) => {
        if (activeAnalysisPanelTab !== tab) {
            setActiveAnalysisPanelTab(tab);
        }
    };

    return (
        <div className={styles.oneshotContainer}>
            <div className={styles.oneshotTopSection}>
                <div className={styles.commandsContainer}>
                    <SettingsButton className={styles.commandButton} onClick={() => setIsConfigPanelOpen(!isConfigPanelOpen)} />
                    <ClearChatButton className={styles.commandButton} onClick={clearChat} disabled={!lastQuestionRef.current || isAskLoading} />
                </div>
                <h1 className={styles.oneshotTitle}>Ask your video library</h1>
                <h3 className={styles.oneshotSubTitle}>
                    <div>This is an example of how AI can find answers from your video library. </div>
                    <div>AI-generated content can have mistakes. Make sure it’s accurate and appropriate before using it.</div>
                </h3>
                <div className={styles.oneshotQuestionInput}>
                    <QuestionInput
                        question={question}
                        placeholder="Example: How many lnguages are supported?"
                        disabled={isAskLoading || isLoading}
                        onSend={question => makeApiRequest(question)}
                    />
                </div>
            </div>
            {!isLoading ? (
                <div className={styles.oneshotBottomSection}>
                    {isAskLoading && <Spinner label="Generating answer" />}
                    {!lastQuestionRef.current && <ExampleList onExampleClicked={onExampleClicked} />}
                    {!isAskLoading && answer && !error && (
                        <div className={styles.oneshotAnswerContainer}>
                            <Answer
                                answer={answer}
                                onCitationClicked={(x, docId) => onShowCitation(x, docId)}
                                onThoughtProcessClicked={() => onToggleTab(AnalysisPanelTabs.ThoughtProcessTab)}
                                onSupportingContentClicked={() => onToggleTab(AnalysisPanelTabs.SupportingContentTab)}
                            />
                        </div>
                    )}
                    {error ? (
                        <div className={styles.oneshotAnswerContainer}>
                            <AnswerError error={error.toString()} onRetry={() => makeApiRequest(lastQuestionRef.current)} />
                        </div>
                    ) : null}
                    {activeAnalysisPanelTab && answer && (
                        <AnalysisPanel
                            className={styles.oneshotAnalysisPanel}
                            activeCitation={activeCitation}
                            activeScene={activeScene}
                            onActiveTabChanged={x => onToggleTab(x)}
                            citationHeight="100%"
                            answer={answer}
                            activeTab={activeAnalysisPanelTab}
                        />
                    )}
                </div>
            ) : (
                <Spinner className={styles.loadingIndexes} label="Loading" />
            )}
            <Panel
                headerText="Configure answer generation"
                isOpen={isConfigPanelOpen}
                isBlocking={false}
                onDismiss={() => setIsConfigPanelOpen(false)}
                closeButtonAriaLabel="Close"
                onRenderFooterContent={() => <DefaultButton onClick={() => setIsConfigPanelOpen(false)}>Close</DefaultButton>}
                isFooterAtBottom={true}
            >
                <SpinButton
                    className={styles.oneshotSettingsSeparator}
                    label="Retrieve this many documents from search:"
                    min={1}
                    max={50}
                    defaultValue={retrieveCount.toString()}
                    onChange={onRetrieveCountChange}
                />
                <div className={styles.oneshotSettingsSeparator}>
                    <IndexesDropdown indexes={indexes} onIndexChanged={onIndexChanged} />
                </div>
            </Panel>
        </div>
    );
};

export default OneShot;
