import { BaseWidget } from '../../base';
import { IWidgetOptions } from '../../common/options';
import { IVIInsightsWidgetConfig } from './definitions/vi-widget-config.definitions';
export declare class VIInsightsWidget extends BaseWidget {
    private config;
    constructor(elementID: string, options: IWidgetOptions, config: IVIInsightsWidgetConfig);
    protected get iframeUrl(): string;
    protected communicate(event: MessageEvent): void;
}
