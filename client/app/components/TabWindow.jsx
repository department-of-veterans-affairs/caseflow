import React from 'react';
import PropTypes from 'prop-types';

import { Tabs } from './tabs/Tabs';
import { Tab } from './tabs/Tab';

/*
 * This component can be used to easily build tabs.
 * The required props are:
 * - @tabs {array[string]} array of strings placed in the tabs at the top
 * of the window
 * - @pages {array[node]} array of nodes displayed when the corresponding
 * tab is selected
 * Optional props:
 * - @name {string} used in each tab ID to differentiate multiple sets of tabs
 * on a page. This is for accessibility purposes.
 */
const TabWindow = (props) => {
  const {
    fullPage = false,
    defaultPage = 0,
    name = 'main',
    onChange,
    tabs = [],
    tabPanelTabIndex = null,
    tabPanelClassName = null,
    alwaysShowTabs,
    mountOnEnter = true,
    unmountOnExit = true,
  } = props;

  const tabContent = (tab) => (
    <span>
      {tab.icon ?? ''}
      <span>{tab.label}</span>
      {tab.indicator ?? ''}
    </span>
  );

  // If there's only one tab, avoid rendering out tabs and just display the content.
  // This avoids any weird accessibility issues of having a tabpanel w/o corresponding tab
  if (tabs.length === 1 && !alwaysShowTabs) {
    return tabs[0].page;
  }

  return (
    <Tabs
      fullWidth={fullPage}
      idPrefix={name}
      active={defaultPage.toString()}
      onChange={onChange}
      mountOnEnter={mountOnEnter}
      unmountOnExit={unmountOnExit}
      tabPanelTabIndex={tabPanelTabIndex}
      tabPanelClassName={tabPanelClassName}
    >
      {tabs.map((item, idx) => (
        <Tab
          title={tabContent(item)}
          key={idx}
          value={idx}
          disabled={Boolean(item.disable)}
        >
          {item.page}
        </Tab>
      ))}
    </Tabs>
  );
};

TabWindow.propTypes = {
  fullPage: PropTypes.bool,
  name: PropTypes.string,
  onChange: PropTypes.func,
  tabs: PropTypes.arrayOf(
    PropTypes.shape({
      disable: PropTypes.bool,
      icon: PropTypes.obj,
      indicator: PropTypes.obj,
      label: PropTypes.node.isRequired,
      page: PropTypes.node.isRequired,
    })
  ),
  defaultPage: PropTypes.number,
  tabPanelTabIndex: PropTypes.number,
  tabPanelClassName: PropTypes.string,
  alwaysShowTabs: PropTypes.bool,
  mountOnEnter: PropTypes.bool,
  unmountOnExit: PropTypes.bool,
};

TabWindow.defaultProps = {
  defaultPage: 0,
  fullPage: false,
  alwaysShowTabs: false,
  mountOnEnter: true,
  unmountOnExit: true,
  tabPanelClassName: null,
};

export default TabWindow;
