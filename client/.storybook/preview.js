import { addParameters } from '@storybook/react';
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

addParameters({ a11y: {} });

// Generate arguments for any props that start with "on" (onClick, onSubmit, etc)
// This *should* work, but isn't currently on beta.21
// addParameters({ actions: { argTypesRegex: '^on.*' } });
