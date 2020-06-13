import React, { useContext } from 'react';
import PropTypes from 'prop-types';

import cx from 'classnames';
import { TabContext } from './TabContext';

const propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  children: PropTypes.node.isRequired,
  disabled: PropTypes.bool,
  value: PropTypes.string.isRequired,
};

export const TabItem = ({
  as: Component = 'button',
  className = '',
  children,
  disabled = false,
  value,
}) => {
  const ctx = useContext(TabContext);
  const active = ctx.value === value;
  const classNames = cx('cf-tab', className, { 'cf-active': active });

  const handleClick = () => ctx.onSelect(value);

  return (
    <Component
      id={`${ctx.idPrefix}-tab`}
      role="tab"
      aria-selected={active}
      aria-controls={`${ctx.idPrefix}-tabpanel`}
      tabIndex={active ? 0 : -1}
      className={classNames}
      disabled={disabled}
      onClick={handleClick}
      data-value={value}
    >
      <span>
        <span>
          <span>{children}</span>
        </span>
      </span>
    </Component>
  );
};
TabItem.propTypes = propTypes;
