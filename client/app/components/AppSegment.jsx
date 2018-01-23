import React from 'react';
import classNames from 'classnames';
import { css } from 'glamor';

// extraClassNames is only to help with migration, but should not be used for new code.
// We should be adding properties to PrimaryAppContent and applying styling within this
// component, instead of applying new class names.
const AppSegment = ({ children, extraClassNames, filledBackground, noMarginTop, styling }) => {
  const marginTopStyling = noMarginTop ?
  // Normally !important is bad, but with CSS-in-JS, I feel comfortable saying that this style
  // should always take precedence.
    css({ marginTop: '0 !important' }) :
    {};

  return <div {...marginTopStyling} {...styling} className={classNames('cf-app-segment', extraClassNames, {
    'cf-app-segment--alt': filledBackground
  })}>
    {children}
  </div>;
};

export default AppSegment;
