import { BaseWidget } from '../../base';
import { IWidgetOptions } from '../../common/options';
import { ICustomInsightsWidgetConfig } from './definitions/custom-insights-config.definitions';
export declare class CustomInsightsWidget extends BaseWidget {
    private config;
    constructor(elementID: string, options: IWidgetOptions, config: ICustomInsightsWidgetConfig);
    protected get iframeUrl(): string;
    protected communicate(event: MessageEvent): void;
}
