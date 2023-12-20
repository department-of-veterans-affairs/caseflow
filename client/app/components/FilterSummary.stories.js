import React from 'react';

import FilterSummary from './FilterSummary';

export default {
  title: 'Commons/Components/FilterSummary',
  component: FilterSummary,
  decorators: [],
  args: {
    filteredByList: {
      'appeal.caseType': ['Original', 'Post Remand'],
      label: ['Review'],
    },
  },
  argTypes: {
    clearFilteredByList: { action: 'clearFilteredByList' },
  },
};

const Template = (args) => <FilterSummary {...args} />;

export const Default = Template.bind({});
