import PropTypes from 'prop-types';

import { TabContainer } from './TabContainer';
import { TabContent } from './TabContent';
import { TabList } from './TabList';
import { TabPanel } from './TabPanel';
import { TabItem } from './TabItem';
import TabContextProvider from './TabContext';

const propTypes = {

  /**
   * The text, component, or element that will be used for the tab header content
   */
  title: PropTypes.node.isRequired,
};

export const Tab = () => {
  return null;
};
Tab.propTypes = propTypes;

Tab.Container = TabContainer;
Tab.Content = TabContent;
Tab.Context = TabContextProvider;
Tab.Item = TabItem;
Tab.List = TabList;
Tab.Panel = TabPanel;
