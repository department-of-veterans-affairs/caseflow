import React from 'react';
import ReduxBase from 'app/components/ReduxBase';
import { nonCompReducer, mapDataToInitialState } from '../reducers';

import ClaimHistoryPage from './ClaimHistoryPage';

import {
  completeTaskPageData
} from '../../../test/data/queue/nonCompTaskPage/nonCompTaskPageData';

const ReduxDecorator = (Story, options) => {
  const props = {
    ...options.args.data
  };

  return <ReduxBase reducer={nonCompReducer} initialState={mapDataToInitialState(props)}>
    <Story />
  </ReduxBase>;
};

export default {
  title: 'Queue/NonComp/ClaimHistoryPage',
  component: ClaimHistoryPage,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {

  },
};

const Template = (args) => {
  return (
    <ClaimHistoryPage
      {...args}
    />
  );
};

export const ClaimHistoryPageTemplate = Template.bind({});

ClaimHistoryPageTemplate.story = {
  name: 'Completed High level Claims'
};

ClaimHistoryPageTemplate.args = {
  data: {
    ...completeTaskPageData
  }
};

