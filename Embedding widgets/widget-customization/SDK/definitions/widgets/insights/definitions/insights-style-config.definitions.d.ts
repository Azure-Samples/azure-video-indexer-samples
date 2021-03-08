import { IBaseStyleConfig } from '../../base-widget-config.definitions';

export interface IInsightsStyleConfig extends IBaseStyleConfig {
    emotionJoy?: string;
    emotionFear?: string;
    emotionSadness?: string;
    emotionAnger?: string;
    sentimentPositive?: string;
    sentimentNegative?: string;
}
