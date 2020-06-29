import React from 'react';
import PropTypes from 'prop-types';

import cx from 'classnames';

import classes from './Tabs.module.scss';

const propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  children: PropTypes.arrayOf(PropTypes.element).isRequired,
};

export const TabContent = ({
  as: Component = 'div',
  className = '',
  ...props
}) => {
  return (
    <Component
      className={cx(
        'cf-tab-window-body-full-screen',
        classes.tabContent,
        className
      )}
      {...props}
    />
  );
};
TabContent.propTypes = propTypes;
