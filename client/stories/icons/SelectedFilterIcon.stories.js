import React from 'react';
import { SelectedFilterIcon } from '../../app/components/icons/SelectedFilterIcon';

export default {
  title: 'Commons/Components/Icons/SelectedFilterIcon',
  component: SelectedFilterIcon,
  parameters: {
    controls: { expanded: true },
  },
};

const Template = (args) => <SelectedFilterIcon {...args} />;

export const Default = Template.bind({});
Default.parameters = {
  docs: {
    description: {
      component: 'Used with the FilterIcon component.',
    },
  },
};
