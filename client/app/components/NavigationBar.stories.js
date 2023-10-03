import React from 'react';

import NavigationBar from './NavigationBar';
import { BrowserRouter } from 'react-router-dom';

export default {
  title: 'Commons/Components/NavigationBar',
  component: NavigationBar,
};

const Template = (args) => <BrowserRouter><NavigationBar {...args} /></BrowserRouter>;

export const Basic = Template.bind({});
Basic.args = {
  logoProps: {
    accentColor: '#FFCC4E',
    overlapColor: '#CA9E00'
  },
  applicationUrls: [
    { link: '/intake', title: 'Intake' },
    { link: '/decision_reviews/vha', title: 'Decision Review Queue', prefix: 'VHA' },
    { link: '/queue', title: 'Queue' },
    { link: '/search', title: 'Search cases' },
    { link: '/hearings/schedule', title: 'Hearing' }
  ],
  userDisplayName: 'Test user',
  dropdownUrls: [
    { link: '/intake/help', title: 'Help' },
    { link: '/feedback', target: '_blank', title: 'Send Feedback' },
    { link: '/organizations/mail/users', title: 'Mail team management' },
    { border: true, link: 'http://localhost:3000/logout', title: 'Sign Out' },
    { link: 'http://localhost:3000/test/users', title: 'Switch User' }
  ],
};
