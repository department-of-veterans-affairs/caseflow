import React, { useContext } from 'react';
import PropTypes from 'prop-types';

import cx from 'classnames';
import classes from './Tabs.module.scss';
import { TabContext } from './TabContext';

const propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  children: PropTypes.node.isRequired,
  disabled: PropTypes.bool,
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
};

export const TabItem = ({
  as: Component = 'button',
  className = '',
  children,
  disabled = false,
  value,
}) => {
  const ctx = useContext(TabContext);
  const active = ctx.value === value.toString();
  const classNames = cx('cf-tab', className, classes.tab, {
    'cf-active': active,
  });

  const handleClick = () => ctx.onSelect(value);

  return (
    <Component
      id={`${ctx.idPrefix}-tab-${value}`}
      role="tab"
      aria-selected={active}
      aria-controls={`${ctx.idPrefix}-tabpanel-${value}`}
      tabIndex={active ? 0 : -1}
      className={classNames}
      disabled={disabled}
      onClick={handleClick}
      data-value={value}
    >
      <div>{children}</div>
    </Component>
  );
};
TabItem.propTypes = propTypes;
