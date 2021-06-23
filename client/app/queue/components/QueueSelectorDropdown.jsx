import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import DropdownButton from '../../components/DropdownButton';
import COPY from '../../../COPY';

const style = css({
  float: 'right',
  margin: '10px'
});

export default class QueueSelectorDropdown extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      menu: false
    };
  }

  toggleMenuVisible = () => {
    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  };

  render = () => {
    const { items } = this.props;

    if (items.length < 1) {
      return null;
    }

    const list = items.map((item) => {
      return {
        title: item.label,
        target: item.to || item.href
      };
    });

    return <div className="cf-dropdown" {...style}>
      <DropdownButton
        lists={list}
        onClick={this.toggleMenuVisible}
        label={COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL}
      />
    </div>;
  }
}

const hrefOrToRequired = (props, propName, componentName) => {
  if (!props.href && !props.to) {
    return new Error(`The ${componentName} component requires either an 'href' or a 'to' value.`);
  } else if (props.href && props.to) {
    return new Error(`The ${componentName} component should not be given both 'href' and 'to' values.`);
  }
};

QueueSelectorDropdown.propTypes = {
  items: PropTypes.arrayOf(PropTypes.shape({
    key: PropTypes.string.isRequired,
    href: hrefOrToRequired,
    to: hrefOrToRequired,
    label: PropTypes.string.isRequired
  }))
};
