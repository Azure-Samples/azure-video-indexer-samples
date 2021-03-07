import { Locale } from './locale.definitions';
export interface IWidgetBaseConfig {
    locale?: Locale;
    style?: IWidgetStyle;
}
export interface IWidgetStyle {
    theme?: Theme;
    customStyle?: IBaseStyleConfig;
}
export declare type Theme = 'Default' | 'Dark';
export interface IBaseStyleConfig {
    highlight?: string;
    primary?: string;
    primaryHover?: string;
    primaryPress?: string;
    primaryDisable?: string;
    secondaryFill?: string;
    secondaryFillHover?: string;
    secondaryFillPress?: string;
    secondaryStroke?: string;
    componentFill?: string;
    componentStroke?: string;
    componentStrokeAlt?: string;
    playStatus?: string;
    playStatusAlt?: string;
    headerActions?: string;
    headerHovers?: string;
    headerHoversAlt?: string;
    headerBg?: string;
    dividers?: string;
    dividersAlt?: string;
    dividersPanel?: string;
    bgPrimary?: string;
    bgSecondary?: string;
    typePrimary?: string;
    typeSecondary?: string;
    typeDisabled?: string;
    typeDisabledAlt?: string;
    videoMenuBg?: string;
    videoShade?: string;
    errorType?: string;
    errorArea?: string;
    errorAreaTint?: string;
    warningArea?: string;
    shadow?: string;
}
