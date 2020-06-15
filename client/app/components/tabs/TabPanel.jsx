import React, { useContext } from 'react';
import PropTypes from 'prop-types';

import cx from 'classnames';

import classes from './Tabs.module.scss';
import { TabContext } from './TabContext';

const propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  children: PropTypes.node.isRequired,
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
};

export const TabPanel = ({
  as: Component = 'div',
  className = '',
  children,
  value,
}) => {
  const ctx = useContext(TabContext);
  const active = ctx.value === value.toString();

  const classNames = cx(classes.tabPanel, className, { active });

  return (
    <Component
      role="tabpanel"
      id={`${ctx.idPrefix}-tabpanel-${value}`}
      aria-hidden={!active}
      className={classNames}
      tabIndex={active ? 0 : -1}
    >
      {children}
    </Component>
  );
};
TabPanel.propTypes = propTypes;
