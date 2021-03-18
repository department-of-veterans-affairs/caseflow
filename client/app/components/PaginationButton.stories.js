import React from 'react';

import PaginationButton from './Pagination/PaginationButton';

export default {
  title: 'Commons/Components/PaginationButton',
  component: PaginationButton,
  decorators: [],
  args: {
    currentPage: 0,
    index: 0,
  },
  argTypes: {
    handleChange: { action: 'Button clicked' },
  },
};

// Add cf-pagination-pages class to get the appropriate scss from _table.scss
// Set 'float' and 'textAlign' because the story is easier to read with
//   the button on the left
const Template = (args) =>
  <div className="cf-pagination-pages" style={{ float: 'left', textAlign: 'left' }}>
    <PaginationButton {...args} />
  </div>;

export const CurrentPage = Template.bind({});

export const OtherPage = Template.bind({});
OtherPage.args = {
  currentPage: 3,
  index: 0,
};
