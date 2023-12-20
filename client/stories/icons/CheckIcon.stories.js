import React from 'react';
import { CheckIcon } from '../../app/components/icons/fontAwesome/CheckIcon';

export default {
  title: 'Commons/Components/Icons/CheckIcon',
  component: CheckIcon,
};

const Template = (args) => <CheckIcon {...args} />;

export const Default = Template.bind({});
Default.parameters = {
  docs: {
    description: {
      component: 'This is a Font Awesome Icon and gets no props.',
    },
  },
};
