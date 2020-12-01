import React from 'react';
import { MemoryRouter } from 'react-router';
import NavigationBar from './NavigationBar';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';
import { LOGO_COLORS } from '../constants/AppConstants';

export default {
  title: 'Commons/Components/Layout/NavigationBar',
  component: NavigationBar,
  decorators: [() => (<MemoryRouter><NavigationBar /></MemoryRouter>)]
};

const Template = (args) => <NavigationBar {...args} />;

export const Basic = Template.bind({});
Basic.args = {
  appName: 'Caseflow App Name',
  key: '/queue',
  extraBanner: <PerformanceDegradationBanner showBanner={false} />,
  logoProps: {
    accentColor: LOGO_COLORS.INTAKE.ACCENT,
    overlapColor: LOGO_COLORS.INTAKE.OVERLAP
  },
  userDisplayName: 'Rick Sanchez',
  dropdownUrls: [{
    title: 'Queue',
    link: '/queue',
    target: '#top',
    border: false
  }],
  topMessage: null,
  defaultUrl: '/'
};
