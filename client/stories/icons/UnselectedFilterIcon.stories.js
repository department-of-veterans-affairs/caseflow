import React from 'react';
import { UnselectedFilterIcon } from '../../app/components/icons/UnselectedFilterIcon';

export default {
  title: 'Commons/Components/Icons/UnselectedFilterIcon',
  component: UnselectedFilterIcon,
  parameters: {
    controls: { expanded: true },
  },
};

const Template = (args) => <UnselectedFilterIcon {...args} />;

export const Default = Template.bind({});
