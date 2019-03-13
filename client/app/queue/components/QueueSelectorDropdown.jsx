import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from '../../../COPY.json';

// NOTE: parent container needs to be given 'position: relative'
const styles = {
  dropdownTrigger: css({
    marginRight: 0
  }),
  dropdownButton: css({
    position: 'absolute',
    top: '48px',
    right: '40px'
  }),
  dropdownList: css({
    top: '3.55rem',
    right: '0',
    width: '26rem'
  })
};

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
    let dropdownButtonList;

    if (items.length < 1) {
      return null;
    }

    if (this.state.menu) {
      dropdownButtonList = <ul className="cf-dropdown-menu active" {...styles.dropdownList}>
        {items.map((item) => {
          const linkProps = {
            className: 'usa-button-secondary usa-button',
            onClick: this.toggleMenuVisible,
            href: item.href,
            to: item.to
          };

          return <li key={item.key}>
            <Link {...linkProps}>
              {item.label}
            </Link>
          </li>;
        })}
      </ul>;
    }

    return <div className="cf-dropdown" {...styles.dropdownButton}>
      <a onClick={this.toggleMenuVisible}
        className="cf-dropdown-trigger usa-button usa-button-secondary"
        {...styles.dropdownTrigger}>
        {COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL}
      </a>
      {dropdownButtonList}
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
