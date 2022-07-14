/* eslint-disable no-unused-vars */
import { Component } from '@angular/core';
import {
    CustomInsightsWidget,
    IBaseStyleConfig,
    ICustomColorElement,
    ICustomData,
    ICustomElement,
    ICustomInsightsWidgetConfig,
    IEmotion,
    ITopic,
    IInsightsWidgetConfig,
    IWidgetStyle,
    InsightsWidget
} from '@azure/video-indexer-widgets';

@Component({
    selector: 'app-root',
    templateUrl: './app.component.html'
})
export class AppComponent {
    public insightsWidget: InsightsWidget;
    public ngAfterViewInit(): void {
        const insightsStyleConfig2: IBaseStyleConfig = {
            primary: 'yellow',
            dividers: 'rgba(134,28,173,1)'
        };

        const style: IWidgetStyle = {
            customStyle: insightsStyleConfig2,
            theme: 'Dark'
        };
        const config: IInsightsWidgetConfig = {
            accountId: '00000000-0000-0000-0000-000000000000',
            videoId: 'd9d4860279',
            // accessToken: '<ACCESS-TOKEN>',
            locale: 'es-es',
            tab: 'timeline',
            components: ['emotions', 'sentiments', 'transcript', 'keywords'],
            style: style
        };
        this.insightsWidget = new InsightsWidget(
            'container',
            {
                height: 780,
                width: 580
            },
            config
        );

        this.insightsWidget.render();

        //  Custom insights widget
        const emotions: IEmotion[] = [
            {
                id: 1,
                type: 'Joy',
                instances: [
                    {
                        adjustedEnd: '0:06:46.15',
                        adjustedStart: '0:06:42.086',
                        confidence: 0.6808,
                        end: '0:06:46.15',
                        start: '0:06:42.086'
                    }
                ]
            },
            {
                id: 2,
                type: 'Sad',
                instances: [
                    {
                        adjustedEnd: '0:10:18.957',
                        adjustedStart: '0:09:59.306',
                        confidence: 0.8383,
                        end: '0:10:18.957',
                        start: '0:09:59.306'
                    }
                ]
            }
        ];

        const sentiments = [
            {
                averageScore: 0.5,
                id: 1,
                sentimentType: 'Neutral',
                instances: [
                    {
                        adjustedEnd: '0:06:42.086',
                        adjustedStart: '0:00:00',
                        end: '0:06:42.086',
                        start: '0:00:00'
                    }
                ]
            },
            {
                id: 2,
                sentimentType: 'Positive',
                averageScore: 0.9521,
                instances: [
                    {
                        adjustedEnd: '0:06:46.15',
                        adjustedStart: '0:06:42.086',
                        end: '0:06:46.15',
                        start: '0:06:42.086'
                    }
                ]
            },
            {
                id: 3,
                sentimentType: 'Negative',
                averageScore: 0.1677,
                instances: [
                    {
                        adjustedEnd: '0:10:18.957',
                        adjustedStart: '0:09:59.306',
                        end: '0:10:18.957',
                        start: '0:09:59.306'
                    }
                ]
            }
        ];

        const topics: ITopic[] = [
            {
                confidence: 0.7577,
                id: 1,
                name: 'Brand Audit',
                referenceId: 'Brand Audit',
                language: 'en-US',
                instances: [
                    {
                        adjustedEnd: '0:01:52.838',
                        adjustedStart: '0:00:13.712',
                        end: '0:01:52.838',
                        start: '0:00:13.712'
                    },
                    {
                        adjustedEnd: '0:03:16.21',
                        adjustedStart: '0:02:08.093',
                        end: '0:03:16.21',
                        start: '0:02:08.093'
                    }
                ]
            },
            {
                confidence: 0.4893,
                iabName: 'News and Politics',
                id: 23,
                instances: [
                    {
                        adjustedEnd: '0:02:59.015',
                        adjustedStart: '0:00:08.421',
                        end: '0:02:59.015',
                        start: '0:00:08.421'
                    }
                ],
                iptcName: 'Politics/election',
                language: 'en-US',
                name: 'Political Campaigns and Elections',
                referenceId: 'Politics and Government/Political Campaigns and Elections',
                referenceType: 'VideoIndexer'
            },
            {
                confidence: 0.6453,
                iabName: 'Business and Finance',
                id: 14,
                instances: [
                    {
                        adjustedEnd: '0:02:37.644',
                        adjustedStart: '0:00:00',
                        end: '0:02:37.644',
                        start: '0:00:00'
                    },
                    {
                        adjustedEnd: '0:04:01.497',
                        adjustedStart: '0:03:39.322',
                        end: '0:04:01.497',
                        start: '0:03:39.322'
                    },
                    {
                        adjustedEnd: '0:05:00.968',
                        adjustedStart: '0:04:36.6',
                        end: '0:05:00.968',
                        start: '0:04:36.6'
                    }
                ],
                iptcName: 'Economy, Business and Finance/business (general)',
                language: 'en-US',
                name: 'Brand Strategy',
                referenceId: 'Business/Product Development/Brand Strategy',
                referenceType: 'VideoIndexer'
            }
        ];

        const customElement2 = {
            id: 1,
            text: 'Hello',
            instances: [
                {
                    adjustedEnd: '0:00:12.44',
                    adjustedStart: '0:00:11.54',
                    end: '0:00:12.44',
                    start: '0:00:11.54'
                },
                {
                    adjustedEnd: '0:05:27.96',
                    adjustedStart: '0:05:19.89',
                    end: '0:05:27.96',
                    start: '0:05:19.89'
                },
                {
                    adjustedEnd: '0:02:06.443',
                    adjustedStart: '0:02:00.83',
                    end: '0:02:06.443',
                    start: '0:02:00.83'
                },
                {
                    adjustedEnd: '0:03:45.44',
                    adjustedStart: '0:03:43.21',
                    end: '0:03:45.44',
                    start: '0:03:43.21'
                }
            ]
        };

        const customElement: ICustomElement = {
            id: 1,
            text: 'What',
            instances: [
                {
                    adjustedEnd: '0:02:37.644',
                    adjustedStart: '0:00:00',
                    end: '0:02:37.644',
                    start: '0:00:00'
                },
                {
                    adjustedEnd: '0:04:01.497',
                    adjustedStart: '0:03:39.322',
                    end: '0:04:01.497',
                    start: '0:03:39.322'
                },
                {
                    adjustedEnd: '0:05:00.968',
                    adjustedStart: '0:04:36.6',
                    end: '0:05:00.968',
                    start: '0:04:36.6'
                }
            ]
        };

        const customColorElement: ICustomColorElement = {
            id: 1,
            text: 'Hello!!!!!',
            color: 'blue',
            instances: [
                {
                    adjustedEnd: '0:02:37.644',
                    adjustedStart: '0:00:00',
                    end: '0:02:37.644',
                    start: '0:00:00'
                },
                {
                    adjustedEnd: '0:04:01.497',
                    adjustedStart: '0:03:39.322',
                    end: '0:04:01.497',
                    start: '0:03:39.322'
                },
                {
                    adjustedEnd: '0:05:00.968',
                    adjustedStart: '0:04:36.6',
                    end: '0:05:00.968',
                    start: '0:04:36.6'
                }
            ]
        };

        const customColorElement2 = {
            id: 2,
            text: 'Second color',
            color: 'darkmagenta',
            instances: [
                {
                    adjustedEnd: '0:06:46.15',
                    adjustedStart: '0:06:42.086',
                    end: '0:06:46.15',
                    start: '0:06:42.086'
                }
            ]
        };

        const customColorElement3 = {
            id: 3,
            text: 'Should show white',
            color: '#FFFFF',
            instances: [
                {
                    adjustedEnd: '0:10:18.957',
                    adjustedStart: '0:09:59.306',
                    confidence: 0.8383,
                    end: '0:10:18.957',
                    start: '0:09:59.306'
                }
            ]
        };

        const customColorData: ICustomData = {
            title: 'My Color',
            key: 'myColor',
            presets: ['all', 'accessibility'],
            type: 'color-map',
            sortedBy: {
                order: 'desc',
                property: 'name'
            },
            items: [customColorElement, customColorElement2, customColorElement3]
        };

        const customData: ICustomData = {
            title: 'My Data',
            key: 'myData',
            presets: ['all', 'captioning'],
            type: 'capsule',
            items: [customElement, customElement2]
        };

        const insightsStyleConfig = {
            primary: 'rgba(255,59,209,1)',
            componentFill: 'rgba(33,59,209,1)',
            headerActions: 'rgba(26,188,156,1)',
            dividers: 'rgba(134,28,173,1)',
            bgSecondary: 'rgba(189,224,255,0.4)',
            bgPrimary: 'rgba(255,144,144,1)'
        };

        const lowKeyStyle = {
            highlight: 'rgba(14,182,255,1)',
            primary: 'rgba(13,11,0,1)',
            primaryHover: 'rgba(64,55,55,1)',
            primaryPress: 'rgba(91,78,78,1)',
            primaryDisable: 'rgba(0,0,0,0.050)',
            secondaryFill: 'rgba(0,0,0,0.050)',
            secondaryFillHover: 'rgba(0,0,0,0.080)',
            secondaryFillPress: 'rgba(91,78,78,0.2)',
            secondaryStroke: 'rgba(91,78,78,0.6)',
            componentFill: 'rgba(255,255,255,1)',
            componentStroke: 'rgba(91,78,78,0.6)',
            componentStrokeAlt: 'rgba(91,78,78,0.8)',
            playStatus: 'rgba(13,167,234,0.200)',
            playStatusAlt: 'rgba(14,182,255,0.750)',
            headerActions: 'rgba(255,255,255,1)',
            headerHovers: 'rgba(255,255,255,0.380)',
            headerHoversAlt: 'rgba(255,255,255,0.760)',
            headerBg: 'rgba(28,28,28,1)',
            dividers: 'rgba(91,78,78,0.1)',
            dividersAlt: 'rgba(91,78,78,0.1)',
            dividersPanel: 'rgba(91,78,78,0.2)',
            bgPrimary: 'rgba(250,249,247,1)',
            bgSecondary: 'rgba(246,245,243,1)',
            typePrimary: 'rgba(64,55,55,1)',
            typeSecondary: 'rgba(64,55,55,0.700)',
            typeDisabled: 'rgba(64,55,55,0.420)',
            typeDisabledAlt: 'rgba(64,55,55,0.300)',
            emotionJoy: 'rgba(242,97,12,1)',
            emotionFear: 'rgba(166,8,148,1)',
            emotionSadness: 'rgba(0,120,212,1)',
            emotionAnger: 'rgba(227,0,140,1)',
            sentimentPositive: 'rgba(18,134,110,1)',
            sentimentNegative: 'rgba(235,0,27,1)',
            videoMenuBg: 'rgba(0,0,0,0.800)',
            videoShade: 'rgba(255,255,255,0.380)',
            errorType: 'rgba(168,0,0,1)',
            errorArea: 'rgba(208,46,0,1)',
            errorAreaTint: 'rgba(253,231,233,1)',
            warningArea: 'rgba(255,244,206,1)',
            shadow: 'rgba(64,55,55,0.140)'
        };

        const midnightStyle = {
            highlight: 'rgba(80,230,255,1)',
            primary: 'rgba(80,230,255,1)',
            primaryHover: 'rgba(67,214,238,1)',
            primaryPress: 'rgba(64,199,222,1)',
            primaryDisable: 'rgba(255,255,255,0.120)',
            secondaryFill: 'rgba(8,18,34,1)',
            secondaryFillHover: 'rgba(255,255,255,0.080)',
            secondaryFillPress: 'rgba(255,255,255,0.120)',
            secondaryStroke: 'rgba(255,255,255,0.540)',
            componentFill: 'rgba(36,36,36,1)',
            componentStroke: 'rgba(255,255,255,0.620)',
            componentStrokeAlt: 'rgba(255,255,255,0.760)',
            playStatus: 'rgba(80,230,255,0.250)',
            playStatusAlt: 'rgba(80,230,255,1)',
            headerActions: 'rgba(255,255,255,1)',
            headerHovers: 'rgba(255,255,255,0.380)',
            headerHoversAlt: 'rgba(255,255,255,0.760)',
            headerBg: 'rgba(28,28,28,1)',
            dividers: 'rgba(255,255,255,0.080)',
            dividersAlt: 'rgba(255,255,255,0.120)',
            dividersPanel: 'rgba(255,255,255,0.200)',
            bgPrimary: 'rgba(8,18,34,1)',
            bgSecondary: 'rgba(8,18,34,1)',
            typePrimary: 'rgba(255,250,209,1)',
            typeSecondary: 'rgba(255,250,209,0.760)',
            typeDisabled: 'rgba(255,250,209,0.380)',
            typeDisabledAlt: 'rgba(255,250,209,0.220)',
            emotionJoy: 'rgba(242,124,74,1)',
            emotionFear: 'rgba(192,125,255,1)',
            emotionSadness: 'rgba(77,157,255,1)',
            emotionAnger: 'rgba(255,107,107,1)',
            sentimentPositive: 'rgba(80,230,255,1)',
            sentimentNegative: 'rgba(255,107,107,1)',
            videoMenuBg: 'rgba(0,0,0,0.800)',
            videoShade: 'rgba(255,255,255,0.380)',
            errorType: 'rgba(241,112,123,1)',
            errorArea: 'rgba(208,46,0,1)',
            errorAreaTint: 'rgba(62,29,34,1)',
            warningArea: 'rgba(62,59,29,1)',
            shadow: 'rgba(0,0,0,0.760)'
        };

        const royalBlue = {
            highlight: 'rgba(209,0,209,1)',
            primary: 'rgba(209,0,209,1)',
            primaryHover: 'rgba(192,7,192,1)',
            primaryPress: 'rgba(180,13,180,1)',
            primaryDisable: 'rgba(110,150,181,0.200)',
            secondaryFill: 'rgba(241,249,255,1)',
            secondaryFillHover: 'rgba(209,234,255,0.500)',
            secondaryFillPress: 'rgba(209,234,255,0.700)',
            secondaryStroke: 'rgba(33,72,209,0.700)',
            componentFill: 'rgba(246,251,255,1)',
            componentStroke: 'rgba(33,72,209,0.800)',
            componentStrokeAlt: 'rgba(33,72,209,0.900)',
            playStatus: 'rgba(192,7,192,0.100)',
            playStatusAlt: 'rgba(192,7,192,0.600)',
            headerActions: 'rgba(255,255,255,1)',
            headerHovers: 'rgba(255,255,255,0.380)',
            headerHoversAlt: 'rgba(255,255,255,0.760)',
            headerBg: 'rgba(28,28,28,1)',
            dividers: 'rgba(37,151,255,0.100)',
            dividersAlt: 'rgba(37,151,255,0.200)',
            dividersPanel: 'rgba(37,151,255,0.200)',
            bgPrimary: 'rgba(255,255,255,1)',
            bgSecondary: 'rgba(248,248,248,1)',
            typePrimary: 'rgba(0,57,255,1)',
            typeSecondary: 'rgba(33,72,209,0.800)',
            typeDisabled: 'rgba(33,72,209,0.500)',
            typeDisabledAlt: 'rgba(33,72,209,0.250)',
            emotionJoy: 'rgba(242,97,12,1)',
            emotionFear: 'rgba(166,8,148,1)',
            emotionSadness: 'rgba(0,120,212,1)',
            emotionAnger: 'rgba(227,0,140,1)',
            sentimentPositive: 'rgba(8,170,136,1)',
            sentimentNegative: 'rgba(227,0,140,1)',
            videoMenuBg: 'rgba(33,72,209,0.800)',
            videoShade: 'rgba(33,72,209,0.400)',
            errorType: 'rgba(203,14,14,1)',
            errorArea: 'rgba(222,75,33,1)',
            errorAreaTint: 'rgba(248,219,211,1)',
            warningArea: 'rgba(255,241,191,1)',
            shadow: 'rgba(122,137,188,0.200)'
        };

        const insightsConfig: ICustomInsightsWidgetConfig = {
            duration: 634,
            rawInsightsData: [
                {
                    rawInsightsKey: 'emotions',
                    insightsItems: emotions
                },
                {
                    rawInsightsKey: 'sentiments',
                    insightsItems: sentiments
                },
                {
                    rawInsightsKey: 'topics',
                    insightsItems: topics
                }
            ],
            customData: [customData, customColorData],
            viInsightsKeys: ['brands', 'keywords', 'scenes', 'blocks'],
            accountId: '244dffb2-d95f-4f9f-a90b-698de871a14b',
            videoId: '37075bedb4',
            style: {
                // customStyle: midnightStyle,
                customStyle: royalBlue
                // customStyle: lowKeyStyle,
                // customStyle: insightsStyleConfig,
                // theme: 'Dark'
            }
        };

        const customInsightsWidget = new CustomInsightsWidget(
            'custom-widget-container',
            {
                width: 800,
                height: 1000
            },
            insightsConfig
        );

        customInsightsWidget.render();
    }

    public get apiVersion() {
        return this.insightsWidget?.apiVersion;
    }
}