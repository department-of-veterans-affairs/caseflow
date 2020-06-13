import React from 'react';
import PropTypes from 'prop-types';

import cx from 'classnames';

import classes from './Tabs.module.scss';
import { Tab } from './Tab';

const propTypes = {
  children: PropTypes.arrayOf(PropTypes.element).isRequired,
};

export const Tabs = ({ children }) => {
  const renderTabs = (child) => {
    const { title, value } = child.props;

    return <Tab.Item value={value}>{title}</Tab.Item>;
  };

  const renderPanels = (child) => {
    const { value, children: contents } = child.props;

    return <Tab.Panel value={value}>{contents}</Tab.Panel>;
  };

  return (
    <Tab.Container>
      <Tab.List>{children.map(renderTabs)}</Tab.List>
      <Tab.Content>{children.map(renderPanels)}</Tab.Content>
    </Tab.Container>
  );
};
Tabs.propTypes = propTypes;
