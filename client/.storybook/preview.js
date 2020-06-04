import { addParameters, addDecorator } from '@storybook/react';
import { DocsPage, DocsContainer } from '@storybook/addon-docs/blocks';

import '../app/styles/app.scss';

// Enables root-level grouping in sidebar (styled differently than a folder)
addParameters({ options: { showRoots: true } });

addParameters({
  docs: {
    container: DocsContainer,
    page: DocsPage
  }
});

addParameters({
  a11y: {}
});
