import { configure, addDecorator } from '@storybook/react';
import { withA11y } from '@storybook/addon-a11y';
import centered from '@storybook/addon-centered/react';

// automatically import all files ending in *.stories.js
configure(
  [require.context('../stories', true, /\.stories\.js$/), require.context('../app', true, /\.stories\.js$/)],
  module
);

addDecorator(withA11y);
addDecorator(centered);

import '../app/styles/app.scss';
