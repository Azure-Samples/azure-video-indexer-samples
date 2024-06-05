import { useState, useEffect } from "react";
import { Stack, TextField } from "@fluentui/react";
import { Send28Filled } from "@fluentui/react-icons";

import styles from "./QuestionInput.module.css";

interface Props {
    onSend: (question: string) => void;
    question?: string;
    disabled: boolean;
    placeholder?: string;
    clearOnSend?: boolean;
}

export const QuestionInput = ({ onSend, question, disabled, placeholder, clearOnSend }: Props) => {
    const [value, setValue] = useState<string>(question || "");
    const sendQuestion = () => {
        if (disabled || !value?.trim()) {
            return;
        }

        onSend(value);

        if (clearOnSend) {
            setValue("");
        }
    };

    useEffect(() => {
        setValue(question || "");
    }, [question]);

    const onEnterPress = (ev: React.KeyboardEvent<Element>) => {
        if (ev.key === "Enter" && !ev.shiftKey) {
            ev.preventDefault();
            sendQuestion();
        }
    };

    const onQuestionChange = (_ev: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>, newValue?: string) => {
        if (!newValue) {
            setValue("");
        } else if (newValue.length <= 1000) {
            setValue(newValue);
        }
    };

    const sendQuestionDisabled = disabled || !value?.trim();

    return (
        <Stack horizontal className={styles.questionInputContainer}>
            <TextField
                className={styles.questionInputTextArea}
                placeholder={placeholder}
                multiline
                autoAdjustHeight={true}
                resizable={false}
                borderless
                value={value}
                onChange={onQuestionChange}
                onKeyDown={onEnterPress}
            />
            <div className={styles.questionInputButtonsContainer}>
                <div
                    className={`${styles.questionInputSendButton} ${sendQuestionDisabled ? styles.questionInputSendButtonDisabled : ""}`}
                    aria-label="Ask question button"
                    onClick={sendQuestion}
                >
                    <Send28Filled primaryFill="rgba(16, 110, 190, 1)" />
                </div>
            </div>
        </Stack>
    );
};
