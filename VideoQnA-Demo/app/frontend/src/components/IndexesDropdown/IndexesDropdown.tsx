import { Dropdown, IDropdownOption, IDropdownStyles } from "@fluentui/react/lib/Dropdown";

interface Props {
    indexes: IDropdownOption[];
    onIndexChanged: (index: string) => void;
}
const dropdownStyles: Partial<IDropdownStyles> = {
    dropdown: {}
};
export const IndexesDropdown = ({ indexes, onIndexChanged }: Props) => {
    const onChange = (event: React.FormEvent<HTMLDivElement>, item: IDropdownOption | undefined): void => {
        onIndexChanged(item!.key as string);
    };
    return (
        <div>
            <Dropdown label="Video Library" placeholder="Select video library" options={indexes} styles={dropdownStyles} onChange={onChange} />
        </div>
    );
};
