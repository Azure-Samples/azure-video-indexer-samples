import { AccountLocation, IInsightsConfig } from '../../definitions/insights-config.definitions';
export interface IVIInsightsWidgetConfig extends IInsightsConfig {
    accountId: string;
    videoId: string;
    accessToken?: string;
    location?: AccountLocation;
}
export declare enum InsightsWidgetMessage {
    INSIGHTS_WIDGET_LOADED = "INSIGHTS_WIDGET_LOADED",
    INSIGHTS_WIDGET_INIT = "INSIGHTS_WIDGET_INIT"
}
