import React from 'react';
import PropTypes from 'prop-types';

import { Tab } from './Tab';

const propTypes = {
  active: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  idPrefix: PropTypes.string,
  children: PropTypes.arrayOf(PropTypes.element).isRequired,
  fullWidth: PropTypes.bool,
};

export const Tabs = ({
  active = '1',
  idPrefix,
  children,
  fullWidth = false,
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
      <Tab.Panel value={value} key={value} fullWidth={fullWidth}>
        {contents}
      </Tab.Panel>
    );
  };

  return (
    <Tab.Container idPrefix={idPrefix} active={active}>
      <Tab.List fullWidth={fullWidth}>{children.map(renderTabs)}</Tab.List>
      <Tab.Content>{children.map(renderPanels)}</Tab.Content>
    </Tab.Container>
  );
};
Tabs.propTypes = propTypes;
