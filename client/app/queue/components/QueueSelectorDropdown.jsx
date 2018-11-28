// @flow
import React from 'react';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
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
  organizations: Array<Object>
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
    const { organizations } = this.props;
    const url = window.location.pathname.split('/');
    const location = url[url.length - 1];

    const dropdownButtonList = (orgs) => {
      const queueHref = (location === 'queue') ? '#' : '/queue';

      return <ul className="cf-dropdown-menu active" {...styles.dropdownList}>
        <li key={0}>
          <Link className="usa-button-secondary usa-button"
            href={queueHref} onClick={this.onMenuClick}>
            {COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_OWN_CASES_LABEL}
          </Link>
        </li>

        {orgs.map((org, index) => {
          const orgHref = (location === org.url) ? '#' : `/organizations/${org.url}`;

          return <li key={index + 1}>
            <Link className="usa-button-secondary usa-button"
              href={orgHref} onClick={this.onMenuClick}>
              {sprintf(COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL, org.name)}
            </Link>
          </li>;
        })}
      </ul>;
    };

    if (organizations.length < 1) {
      return null;
    }

    return <div className="cf-dropdown" {...styles.dropdownButton}>
      <a onClick={this.onMenuClick}
        className="cf-dropdown-trigger usa-button usa-button-secondary"
        {...styles.dropdownTrigger}>
        {COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL}
      </a>
      {this.state.menu && dropdownButtonList(organizations) }
    </div>;
  }
}

QueueSelectorDropdown.propTypes = {
  organizations: PropTypes.arrayOf(PropTypes.shape({
    name: PropTypes.string.isRequired,
    url: PropTypes.string.isRequired
  }))
};
