import React from 'react';

import ProgressBar from './ProgressBar';

export default {
  title: 'Commons/Components/ProgressBar',
  component: ProgressBar,
};

const Template = (args) => <ProgressBar {...args} />;

export const Basic = Template.bind({});
Basic.args = {
  sections: [
    {
      title: '1. Review Description',
    },
    {
      title: '2. Create End Product',
      current: true,
    },
    {
      title: '3. Confirmation',
    },
  ],
};
