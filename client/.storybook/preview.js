import { Preview } from '@storybook/react';
import { DocsPage, DocsContainer } from '@storybook/addon-docs/blocks';
import '../app/styles/app.scss';

// Generate arguments for any props that start with "on" (onClick, onSubmit, etc)
// This *should* work, but isn't currently on beta.21
// addParameters({ actions: { argTypesRegex: '^on.*' } });
const tags = ['autodocs'];

const preview = {
  parameters: {
    docs: {
      container: DocsContainer,
      page: DocsPage,
    },
    a11y: {},
  },
};

export {
  preview,
  tags
};