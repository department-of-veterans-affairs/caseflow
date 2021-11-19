/* eslint-disable max-len */
import React from 'react';
import FilterIcon from '../../app/components/icons/FilterIcon';

export default {
  title: 'Commons/Components/Icons/FilterIcon',
  component: FilterIcon,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    selected: false,
    label: '',
    iconName: '',
    className: 'table-icon',
  }
};

const Template = (args) => <FilterIcon {...args} />;

export const Default = Template.bind({});
Default.parameters = {
  docs: {
    description: {
      component: 'The FilterIcon toggles the SelectedFilterIcon and UnselectedFilterIcon based on the selected props value. The size of this icon is set independently on the SelectedFilterIcon and UnselectedFilterIcon components.',
    },
  },
};
