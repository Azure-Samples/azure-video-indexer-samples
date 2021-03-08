import { Language } from '../../../languages.definitions';
export interface IIndexElementWithType<T> {
    id: number;
    instances: T[];
}
export interface IIndexElementWithLanguage<T> extends IIndexElementWithType<T> {
    language?: Language;
}
export interface ITranscriptLine extends IIndexElementWithLanguage<IElementInstance> {
    text: string;
    confidence: number;
    speakerId: number;
}
export interface IKeyword extends IIndexElementWithLanguage<IElementInstance> {
    text: string;
    confidence: number;
}
export interface ITopic extends IIndexElementWithLanguage<IElementInstance> {
    name: string;
    referenceId: string;
    referenceType?: TopicReferenceType;
    iabName?: string;
    iptcName?: string;
    confidence: number;
    referenceUrl?: string;
}
export declare type TopicReferenceType = 'VideoIndexer' | 'Wikipedia';
export interface IFramePattern extends IIndexElement {
    name: FramePatternType;
}
export declare type FramePatternType = 'RollingCredits' | 'Black';
export interface ILabel extends IIndexElementWithLanguage<ILabelElementInstance> {
    name: string;
    referenceId: string;
}
export interface IAnnotation extends IIndexElementWithLanguage<IElementInstance> {
    name: string;
}
export declare type EmotionType = 'Anger' | 'Fear' | 'Joy' | 'Neutral' | 'Sad';
export interface IEmotion extends IIndexElementWithType<IEmotionElementInstance> {
    type: EmotionType;
}
export interface ISentiment extends IIndexElement {
    averageScore: number;
    sentimentType: SentimentType;
}
export declare type SentimentType = 'Negative' | 'Neutral' | 'Positive' | 'Undetermined';
export interface IAudioEffect extends IIndexElement {
    type: AudioEffectType;
}
export declare type AudioEffectType = 'Unlabeled' | 'Baseline' | 'Laughter' | 'Clapping' | 'Speech' | 'Silence' | 'Gunshot' | 'Alarm' | 'DogBarking' | 'Crying' | 'CrowdReactions' | 'Explosion' | 'Screaming' | 'GlassShattering' | 'Siren';
export interface ISpeaker extends IIndexElement {
    name: string;
}
export declare type BrandType = 'None' | 'Transcript' | 'Ocr';
export interface IBrand extends IIndexElementWithType<IBrandElementInstance> {
    name: string;
    referenceId: string;
    referenceUrl: string;
    referenceType: BrandReferenceType;
    description: string;
    tags: string[];
    confidence: number;
    isCustom: boolean;
}
export interface IBlock extends IIndexElement {
}
export interface INamedPeople extends IIndexElementWithType<IBrandElementInstance> {
    name: string;
    referenceId: string;
    referenceUrl: string;
    referenceType: BrandReferenceType;
    description: string;
    tags: string[];
    confidence: number;
    isCustom: boolean;
}
export interface INamedLocations extends IIndexElementWithType<IBrandElementInstance> {
    name: string;
    referenceId: string;
    referenceUrl: string;
    referenceType: BrandReferenceType;
    description: string;
    tags: string[];
    confidence: number;
    isCustom: boolean;
}
export interface IBrandElementInstance extends IElementInstance {
    brandType: BrandType;
}
export interface ILabelElementInstance extends IElementInstance {
    confidence: number;
}
export interface IEmotionElementInstance extends IElementInstance {
    confidence: number;
}
export declare type BrandReferenceType = 'Wiki';
export interface IIndexElement extends IIndexElementWithType<IElementInstance> {
}
export interface IIndexElementWithType<T> {
    id: number;
    instances: T[];
}
export interface TimeRange {
    start: string;
    end: string;
}
export interface IElementInstance extends TimeRange {
    adjustedStart: string;
    adjustedEnd: string;
}
export interface IOcr extends IIndexElementWithLanguage<IElementInstance> {
    text: string;
    confidence: number;
    left: number;
    top: number;
    width: number;
    height: number;
}
export interface ICustomElement extends IIndexElementWithType<IElementInstance> {
    text: string;
    confidence?: number;
}
export interface ICustomColorElement extends ICustomElement {
    color: string;
}
export declare type ICustomItemElement = ICustomColorElement | ICustomElement;
