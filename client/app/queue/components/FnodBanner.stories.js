import React from 'react';

import FnodBanner from './FnodBanner';

export default {
  title: 'Queue/FNOD Banner',
  component: FnodBanner,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 200,
    },
  },
  args: {
    appeal: {
      veteran_appellant_deceased: true,
      date_of_death: '2019-03-17'
    },
  }
};

const Template = (args) => (
  <FnodBanner {...args} />
);

export const FNODBanner = Template.bind({});
