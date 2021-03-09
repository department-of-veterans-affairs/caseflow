import React from 'react';

import FilterOption from './FilterOption';

/* eslint-disable react/prop-types */

export default {
  title: 'Commons/Components/FilterOption',
  component: FilterOption,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    options: [
      { value: 'option1', displayText: 'Option 1', checked: true },
      { value: 'option2', displayText: 'Option 2', checked: false },
      { value: 'option3', displayText: 'Option 3', checked: false }
    ],
    setSelectedValue: () => {},
  },
};

// I don't understand how to update state in here
// client/app/components/SearchableDropdown.stories.js
// This seems like my best bet for figuring this out?
export const Template = (args) => {
  return <FilterOption {...args} />;
};

export const Something = Template.bind({});
