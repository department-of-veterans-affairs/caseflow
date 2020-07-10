import React from 'react';

import { withKnobs, text, select } from '@storybook/addon-knobs';

import { ReturnToLitSupportAlert } from './ReturnToLitSupportAlert';
import { dispositions } from './mtvConstants';

export default {
  title: 'Queue/Motions to Vacate/Judge Address Motion to Vacate/ReturnToLitSupportAlert',
  component: ReturnToLitSupportAlert,
  decorators: [withKnobs]
};

export const standard = () => (
  <ReturnToLitSupportAlert disposition={select('Disposition', dispositions, 'granted', 'standard')} />
);

standard.story = {
  parameters: {
    docs: {
      storyDescription: 'This provides a link to allow a judge to return a case to lit support if need be'
    }
  }
};
