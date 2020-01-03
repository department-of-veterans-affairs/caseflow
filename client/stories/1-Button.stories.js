import React from 'react';

import { action } from '@storybook/addon-actions';
import { Button } from '@storybook/react/demo';
import { withKnobs, text } from '@storybook/addon-knobs';

export default {
  title: 'Design System|Components/Button',
  decorators: [withKnobs]
};

export const plain = () => <Button onClick={action('clicked')}>{text('Contents', 'Hello Button')}</Button>;

export const emoji = () => (
  <Button onClick={action('clicked')}>
    <span role="img" aria-label="so cool">
      😀 😎 👍 💯
    </span>
  </Button>
);

emoji.story = {
  name: 'with emoji'
};
