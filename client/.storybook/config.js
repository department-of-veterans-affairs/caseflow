import { configure, addDecorator } from '@storybook/react';
import { withA11y } from '@storybook/addon-a11y';
import centered from '@storybook/addon-centered/react';

import '../app/styles/app.scss';

// automatically import all files ending in *.stories.js
configure(
  [
    require.context('../stories', true, /\.(stories|story)\.(js|mdx)$/),
    require.context('../app', true, /\.stories\.js$/)
  ],
  module
);

addDecorator(withA11y);
// addDecorator(centered);

// Centered addon causes layout issues on docs page.
// This is a weird hack to fix the layout issues.
addDecorator((...args) => {
  const params = new URL(document.location).searchParams;
  const isInDocsView = params.get('viewMode') === 'docs';

  if (isInDocsView) {
    return args[0]();
  }

  return centered(...args);
});
