import React from 'react';
import ReviewPage from './ReviewPage';
import ReduxBase from 'app/components/ReduxBase';
import { nonCompReducer, mapDataToInitialState } from '../reducers';
import { vhaTaskFilterDetails } from '../../../test/data/taskFilterDetails';

const ReduxDecorator = (Story, options) => {
  const tabs = (typeValue) => {
    if (typeValue === 'vha') {
      return ['incomplete', 'in_progress', 'completed'];
    }

    return ['in_progress', 'completed'];
  };

  const props = {
    serverNonComp: {
      businessLine: 'Veterans Health Administration',
      businessLineUrl: options.args.businessLineType || 'vha',
      decisionIssuesStatus: {},
      isBusinessLineAdmin: options.args.isBusinessLineAdmin,
      businessLineConfig: {
        tabs: tabs(options.args.businessLineType),
        canGenerateClaimHistory: options.args.canGenerateClaimHistory,
      },
      taskFilterDetails: vhaTaskFilterDetails,
      featureToggles: {
        decisionReviewQueueSsnColumn: true
      }
    }
  };

  return (
    <ReduxBase reducer={nonCompReducer} initialState={mapDataToInitialState(props)}>
      <Story />
    </ReduxBase>
  );
};

const defaultArgs = {
  isBusinessLineAdmin: true,
  canGenerateClaimHistory: true
};

export default {
  title: 'Queue/NonComp/ReviewPage',
  component: ReviewPage,
  decorators: [ReduxDecorator],
  parameters: {},
  args: defaultArgs,
  argTypes: {
    canGenerateClaimHistory: { control: 'boolean' },
    isBusinessLineAdmin: { control: 'boolean' },
    businessLineType: {
      control: {
        type: 'select',
        options: ['vha', 'generic'],
      },
    }
  }
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
