import React from 'react';
import PropTypes from 'prop-types';

import cx from 'classnames';

const propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  children: PropTypes.arrayOf(PropTypes.element).isRequired,
  fullscreen: PropTypes.bool,
};

export const TabList = ({
  as: Component = 'div',
  className = '',
  fullscreen = false,
  ...props
}) => {
  return (
    <Component
      role="tablist"
      className={cx(
        'cf-tab-navigation',
        {
          'cf-tab-navigation-fullscreen': fullscreen,
        },
        className
      )}
      {...props}
    />
  );
};
TabList.propTypes = propTypes;
