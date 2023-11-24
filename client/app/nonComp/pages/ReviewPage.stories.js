import React from 'react';
import ReviewPage from './ReviewPage';
import ReduxBase from 'app/components/ReduxBase';
import { nonCompReducer, mapDataToInitialState } from '../reducers';

const ReduxDecorator = (Story, options) => {
  const props = {
    serverNonComp: {
      featureToggles: {
        decisionReviewQueueSsnColumn: options.args.decisionReviewQueueSsnColumn
      },
      businessLine: options.args.businessLine || 'Veterans Health Administration',
      businessLineUrl: options.args.businessLineUrl || 'vha',
      decisionIssuesStatus: {},
      isBusinessLineAdmin: options.args.isBusinessLineAdmin || false,
      businessLineConfig: {
        canGenerateClaimHistory: options.args.canGenerateClaimHistory || false,
      }
    }
  };

  return (
    <ReduxBase reducer={nonCompReducer} initialState={mapDataToInitialState(props)}>
      <Story />
    </ReduxBase>
  );
};

export default {
  title: 'Queue/NonComp/ReviewPage',
  component: ReviewPage,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {}
};

const Template = (args) => {
  return (
    <ReviewPage
      {...args}
    />
  );
};

export const ReportPageCompleted = Template.bind({});

ReportPageCompleted.story = {
  name: 'Review Page'
};
