import React, { useRef, useContext } from 'react';
import PropTypes from 'prop-types';

import cx from 'classnames';
import { TabContext } from './TabContext';

const propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  children: PropTypes.arrayOf(PropTypes.element).isRequired,
  fullWidth: PropTypes.bool,
  keyNav: PropTypes.bool,
};

export const TabList = ({
  as: Component = 'div',
  className = '',
  fullWidth = false,
  keyNav = true,
  ...props
}) => {
  const ctx = useContext(TabContext);
  const tabListRef = useRef(null);

  const handleKeyDown = (event) => {
    // Keyboard navigation is technically optional, but is important for accessibility
    if (!keyNav) {
      return;
    }

    const { target } = event;

    // Keyboard navigation assumes that [role="tab"] are siblings
    // though we might warn in the future about nested, interactive elements
    // as a a11y violation
    const role = target.getAttribute('role');

    if (role !== 'tab') {
      return;
    }

    const PREV_KEY = 'ArrowLeft';
    const NEXT_KEY = 'ArrowRight';
    const HOME_KEY = 'Home';
    const END_KEY = 'End';

    const children = [...tabListRef.current.childNodes];
    const enabled = children.filter((item) => !item.disabled);
    const firstAllowed = enabled[0] || target;
    const lastAllowed = enabled[enabled.length - 1];
    const nextAllowed = enabled[enabled.indexOf(target) + 1] || target;
    const prevAllowed = enabled[enabled.indexOf(target) - 1] || target;

    let newFocusTarget = null;

    // Look for the appropriate next element, but stay put if at first or last
    switch (event.key) {
    case PREV_KEY:
      newFocusTarget = prevAllowed;
      break;
    case NEXT_KEY:
      newFocusTarget = nextAllowed;
      break;
    case HOME_KEY:
      newFocusTarget = firstAllowed;
      break;
    case END_KEY:
      newFocusTarget = lastAllowed;
      break;
    default:
      break;
    }

    if (newFocusTarget !== null && !newFocusTarget.disabled) {
      newFocusTarget.focus();
      event.preventDefault();
      const { value } = newFocusTarget.dataset;

      ctx.onSelect(value);
    }
  };

  return (
    <Component
      role="tablist"
      className={cx(
        'cf-tab-navigation',
        { 'cf-tab-navigation-full-screen': fullWidth },
        className
      )}
      onKeyDown={handleKeyDown}
      ref={tabListRef}
      {...props}
    />
  );
};
TabList.propTypes = propTypes;
