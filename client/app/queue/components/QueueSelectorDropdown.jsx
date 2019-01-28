// @flow
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

type Props = {|
  items: Array<Object>
|};

type ComponentState = {|
  menu: boolean
|};

export default class QueueSelectorDropdown extends React.Component<Props, ComponentState> {
  constructor(props: Props) {
    super(props);
    this.state = {
      menu: false
    };
  }

  onMenuClick = () => {
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
          return <li key={item.key}>
            <Link className="usa-button-secondary usa-button"
              href={item.href} onClick={this.onMenuClick}>
              {item.label}
            </Link>
          </li>;
        })}
      </ul>;
    }

    return <div className="cf-dropdown" {...styles.dropdownButton}>
      <a onClick={this.onMenuClick}
        className="cf-dropdown-trigger usa-button usa-button-secondary"
        {...styles.dropdownTrigger}>
        {COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL}
      </a>
      {dropdownButtonList}
    </div>;
  }
}

QueueSelectorDropdown.propTypes = {
  items: PropTypes.arrayOf(PropTypes.shape({
    key: PropTypes.string.isRequired,
    href: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired
  }))
};
