import { AccountLocation, IInsightsConfig, PresetType } from '../../definitions/insights-config.definitions';
import { IAudioEffect, IBlock, IBrand, ICustomItemElement, IEmotion, IFramePattern, IKeyword, ILabel, INamedLocations, INamedPeople, IOcr, ISentiment, ISpeaker, ITopic, ITranscriptLine } from './video-insights.definitions';
export declare type VIInsightsDataType = ITranscriptLine | IOcr | IKeyword | ITopic | ILabel | IBrand | INamedPeople | INamedLocations | ISentiment | IEmotion | IBlock | IFramePattern | IAudioEffect | ISpeaker;
export declare type insightsType = 'capsule' | 'color-map';
export declare type VIInsightsKey = 'faces' | 'animatedCharacters' | 'keywords' | 'labels' | 'sentiments' | 'emotions' | 'topics' | 'shots' | 'keyframes' | 'transcript' | 'ocr' | 'speakers' | 'scenes' | 'brands' | 'namedPeople' | 'namedLocations' | 'audioEffects' | 'blocks' | 'framePatterns';
export declare type VIRawInsightsKey = 'keywords' | 'labels' | 'sentiments' | 'emotions' | 'topics' | 'transcript' | 'ocr' | 'speakers' | 'brands' | 'namedPeople' | 'namedLocations' | 'audioEffects' | 'blocks' | 'framePatterns';
export interface ICustomData {
    title: string;
    key: string;
    presets: PresetType[];
    type: insightsType;
    items: ICustomItemElement[];
}
export interface IVRawIInsightsData {
    rawInsightsKey: VIRawInsightsKey;
    insightsItems: VIInsightsDataType[];
}
export interface ICustomInsightsWidgetConfig extends IInsightsConfig {
    accountId?: string;
    videoId?: string;
    accessToken?: string;
    location?: AccountLocation;
    duration: number;
    viInsightsKeys: VIInsightsKey[];
    rawInsightsData: IVRawIInsightsData[];
    customData: ICustomData[];
}
export declare enum CustomInsightsWidgetMessage {
    INSIGHTS_WIDGET_LOADED = "INSIGHTS_WIDGET_LOADED",
    CUSTOM_INSIGHTS_WIDGET_INIT = "CUSTOM_INSIGHTS_WIDGET_INIT"
}
