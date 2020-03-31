import React from 'react';

import { withKnobs, object } from '@storybook/addon-knobs';

import ProgressBar from './ProgressBar';

export default {
  title: 'Commons/Components/ProgressBar',
  component: ProgressBar,
  decorators: [withKnobs]
};

const defaultSections = [
  {
    title: '1. Review Description'
  },
  {
    title: '2. Create End Product',
    current: true
  },
  {
    title: '3. Confirmation'
  }
];

export const allOptions = () => <ProgressBar sections={object('Sections', defaultSections, 'allOptions')} />;
