import { CustomInsightsWidget, VIInsightsWidget } from './src/widgets';
declare global {
    interface Widgets {
        Insights: typeof VIInsightsWidget;
        CustomInsights: typeof CustomInsightsWidget;
    }
    interface VI {
        Widgets: Widgets;
    }
    interface Window {
        VI: VI;
    }
}
