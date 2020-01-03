import { configure, addDecorator } from '@storybook/react';
import { withA11y } from '@storybook/addon-a11y';

// automatically import all files ending in *.stories.js
configure(require.context('../stories', true, /\.stories\.js$/), module);

addDecorator(withA11y);
