import { IWidgetOptions } from '../common/options';
export declare abstract class BaseWidget {
    protected elementID: string;
    private _baseUrl;
    protected iframe: HTMLIFrameElement;
    constructor(elementID: string, options: IWidgetOptions);
    render(): void;
    get baseUrl(): string;
    set baseUrl(value: string);
    protected abstract get iframeUrl(): string;
    protected abstract communicate(vent: MessageEvent): void;
}
