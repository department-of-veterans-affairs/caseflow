import React, { useContext, useState, useEffect } from 'react';
import PropTypes from 'prop-types';

import cx from 'classnames';

import classes from './Tabs.module.scss';
import { TabContext } from './TabContext';

const propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  children: PropTypes.node.isRequired,
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  fullWidth: PropTypes.bool,
};

export const TabPanel = ({
  as: Component = 'div',
  className = '',
  children,
  value,
}) => {
  const ctx = useContext(TabContext);
  const active = ctx.value === value.toString();
  const [contents, setContents] = useState(null);

  const classNames = cx(classes.tabPanel, className, { active });

  useEffect(() => {
    if (!ctx.mountOnEnter || (ctx.mountOnEnter && active)) {
      setContents(children);
    }

    if (ctx.unmountOnExit && !active) {
      setContents(null);
    }
  }, [active, ctx.mountOnEnter, ctx.unmountOnExit, children]);

  return (
    <Component
      role="tabpanel"
      id={`${ctx.idPrefix}-tabpanel-${value}`}
      aria-hidden={!active}
      className={classNames}
      tabIndex={-1}
    >
      {contents}
    </Component>
  );
};
TabPanel.propTypes = propTypes;
