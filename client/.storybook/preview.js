import { Preview } from '@storybook/react';
import { DocsPage, DocsContainer } from '@storybook/addon-docs/blocks';
import '../app/styles/app.scss';

//Preview has changed the way addParameters are handle, and addParameters are now
//moved inside a new object called parameters
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