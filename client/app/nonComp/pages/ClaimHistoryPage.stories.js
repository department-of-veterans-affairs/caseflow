import React from 'react';
import ClaimHistoryPage from './ClaimHistoryPage';
import ReduxDecorator from 'test/app/nonComp/nonCompReduxDecorator';
import individualClaimHistoryData from 'test/data/nonComp/individualClaimHistoryData';

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
    ...individualClaimHistoryData
  }
};

