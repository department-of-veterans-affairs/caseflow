import React, { useState } from 'react';

import { addParameters, addDecorator } from '@storybook/react';
import { withA11y } from '@storybook/addon-a11y';
import centered from '@storybook/addon-centered/react';

import '../app/styles/app.scss';

// Enables root-level grouping in sidebar (styled differently than a folder)
addParameters({ options: { showRoots: true } });

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

// Here we roll a custom decorator to enable proper usage of stateful components
const StateWrapper = ({ children }) => {
  const [state, setState] = useState({});

  return <React.Fragment>{children(state, setState)}</React.Fragment>;
};

export const withState = (story) => (
  <StateWrapper>
    {(state, setState) => (
      <React.Fragment>
        {story({
          state,
          setState
        })}
      </React.Fragment>
    )}
  </StateWrapper>
);

// addDecorator(withState);
