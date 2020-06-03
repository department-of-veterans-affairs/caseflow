import { addParameters, addDecorator } from '@storybook/react';
import { withA11y } from '@storybook/addon-a11y';

import '../app/styles/app.scss';

// Enables root-level grouping in sidebar (styled differently than a folder)
addParameters({ options: { showRoots: true } });

addDecorator(withA11y);
