import React from 'react';
import PropTypes from 'prop-types';

import { TabContainer } from './TabContainer';
import { TabContent } from './TabContent';
import { TabList } from './TabList';
import { TabPanel } from './TabPanel';
import { TabItem } from './TabItem';
import TabContextProvider from './TabContext';

const propTypes = {};

export const Tab = ({ children }) => {
  return <React.Fragment />;
};
Tab.propTypes = propTypes;

Tab.Container = TabContainer;
Tab.Content = TabContent;
Tab.Context = TabContextProvider;
Tab.Item = TabItem;
Tab.List = TabList;
Tab.Panel = TabPanel;
