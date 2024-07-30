import React from 'react';
import { CrossIcon } from '../../app/components/icons/fontAwesome/CrossIcon';

export default {
  title: 'Commons/Components/Icons/CrossIcon',
  component: CrossIcon,
};

const Template = (args) => <CrossIcon {...args} />;

export const Default = Template.bind({});
Default.parameters = {
  docs: {
    description: {
      component: 'This is a Font Awesome Icon and gets no props.',
    },
  },
};
