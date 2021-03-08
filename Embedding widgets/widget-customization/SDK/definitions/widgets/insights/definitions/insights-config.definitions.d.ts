import { IWidgetBaseConfig, IWidgetStyle } from '../../base-widget-config.definitions';
import { Language } from '../../languages.definitions';
import { IInsightsStyleConfig } from './insights-style-config.definitions';
export interface IInsightsConfig extends IWidgetBaseConfig {
    tab?: Tab;
    components?: ComponentsParamOption[];
    preset?: PresetType;
    language?: Language;
    controls?: ControlsParamOption[];
    style?: IInsightsStyle;
}
export declare type Tab = 'insights' | 'timeline';
export declare type ComponentsParamOption = 'people' | 'animatedCharacters' | 'keywords' | 'labels' | 'sentiments' | 'emotions' | 'topics' | 'shots' | 'keyframes' | 'transcript' | 'ocr' | 'speakers' | 'scenes' | 'namedEntities' | 'spokenLanguage';
export declare type PresetType = 'all' | 'storyboard' | 'accessibility' | 'captioning';
export declare type ControlsParamOption = 'search' | 'download' | 'presets' | 'language';
export interface IInsightsStyle extends IWidgetStyle {
    customStyle?: IInsightsStyleConfig;
}
export declare type AccountLocation = 'trial' | 'eastus' | 'westus2' | 'eastasia' | 'northeurope' | 'westeurope' | 'southeastasia' | 'eastus2' | 'australiaeast' | 'southcentralus' | 'japaneast' | 'uksouth' | 'switzerlandnorth' | 'switzerlandwest' | 'centralindia';
