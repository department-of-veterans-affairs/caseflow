import React from 'react';

import { withKnobs, text } from '@storybook/addon-knobs';

import CopyTextButton from './CopyTextButton';

export default {
  title: 'Commons/Components/CopyTextButton',
  component: CopyTextButton,
  decorators: [withKnobs]
};

export const allOptions = () => (
  <CopyTextButton
    text={text('Text', 'Lorem ipsum', 'allOptions')}
    textToCopy={text('Text to Copy', '', 'allOptions')}
    label={text('Label', '', 'allOptions')}
  />
);

export const customTextToCopy = () => (
  <CopyTextButton
    text={text('Text', 'Lorem ipsum', 'customTextToCopy')}
    textToCopy={text('Text to Copy', 'I am custom text', 'customTextToCopy')}
    label={text('Label', '', 'customTextToCopy')}
  />
);
