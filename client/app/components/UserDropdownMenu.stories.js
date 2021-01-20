import React from 'react';
import DropdownMenu from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/DropdownMenu';

export default {
  title: 'Commons/Components/Layout/User Dropdown Menu',
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 300,
    },
  },
  args: {
    label: 'BVACHANE at 101 - Candida H Hane',
    options: [
      { title: 'Help', link: '#' },
      { title: 'Send Feedback', link: '#' },
      { title: 'Release History', link: '#' },
      { title: 'Sign Out', link: '#', border: true }
    ]
  },
  argTypes: {
    onClick: { action: 'onClick' },
    onBlur: { action: 'onBlur' },
  }
};

const Template = (args) => (
  <DropdownMenu {...args}
  />
);

// Mock analyticsEvent sent by window in DropdownMenu component
window.analyticsEvent = (...args) => {};

export const UserDropdownMenu = Template.bind({});
