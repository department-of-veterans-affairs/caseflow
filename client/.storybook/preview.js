import React, { useState } from 'react';

import { addParameters, addDecorator } from '@storybook/react';
import { withA11y } from '@storybook/addon-a11y';
import centered from '@storybook/addon-centered/react';

import '../app/styles/app.scss';

// Enables root-level grouping in sidebar (styled differently than a folder)
addParameters({ options: { showRoots: true } });

addDecorator(withA11y);

// Centered addon causes layout issues on docs page.
// Instead of just adding decorator, this is a weird hack to fix the layout issues.
// addDecorator(centered);
addDecorator((...args) => {
  const params = new URL(document.location).searchParams;
  const isInDocsView = params.get('viewMode') === 'docs';

  if (isInDocsView) {
    return args[0]();
  }

  return centered(...args);
});
