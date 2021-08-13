import React from 'react';
import PropTypes from 'prop-types';

import { Tab } from './Tab';

const propTypes = {

  /**
   * Specify value of a given tab to default to selected
   */
  active: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),

  /**
   * String to ensure unique IDs if page contains multiple sets of tabs. Defaults to random string
   */
  idPrefix: PropTypes.string,

  /**
   * One or more `Tab` elements
   */
  children: PropTypes.node.isRequired,

  /**
   * Applies additional styling to better fit full-width layouts
   */
  fullWidth: PropTypes.bool,

  /**
   * Allows the hiding of tabs (for instance, if only one exists); this may affect accessibility
   */
  hideTabs: PropTypes.bool,

  /**
   * Allow for keyboard navigation via arrow keys (important for accessibility)
   */
  keyNav: PropTypes.bool,

  /**
   * Mount tab panel content only when tab is selected
   */
  mountOnEnter: PropTypes.bool,

  /**
   * Unmount tab panel content when tab is exited
   */
  unmountOnExit: PropTypes.bool,

  onChange: PropTypes.func,
  tabPanelTabIndex: PropTypes.bool
};

export const Tabs = ({
  active = '1',
  idPrefix,
  children,
  fullWidth = false,
  hideTabs = false,
  mountOnEnter = false,
  unmountOnExit = false,
  keyNav = true,
  onChange,
  tabPanelTabIndex
}) => {
  const renderTabs = (child) => {
    const { title, value, disabled = false } = child.props;

    return (
      <Tab.Item value={value} key={value} disabled={disabled}>
        {title}
      </Tab.Item>
    );
  };

  const renderPanels = (child) => {
    const { value, children: contents } = child.props;

    return (
      <Tab.Panel value={value} key={value} fullWidth={fullWidth} tabPanelTabIndex={tabPanelTabIndex}>
        {contents}
      </Tab.Panel>
    );
  };

  return (
    <Tab.Container
      idPrefix={idPrefix}
      active={active.toString()}
      onChange={onChange}
      mountOnEnter={mountOnEnter}
      unmountOnExit={unmountOnExit}
    >
      {!hideTabs && (
        <Tab.List fullWidth={fullWidth} keyNav={keyNav}>
          {children.map(renderTabs)}
        </Tab.List>
      )}
      <Tab.Content>{children.map(renderPanels)}</Tab.Content>
    </Tab.Container>
  );
};
Tabs.propTypes = propTypes;
