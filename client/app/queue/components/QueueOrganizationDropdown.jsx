import React from 'react';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';

import QueueSelectorDropdown from './QueueSelectorDropdown';
import COPY from '../../../COPY';

export default class QueueOrganizationDropdown extends React.Component {
  render = () => {
    const { organizations } = this.props;
    const url = window.location.pathname.split('/');
    const location = url[url.length - 1];
    const queueHref = (location === 'queue') ? '#' : '/queue';

    if (organizations.length < 1) {
      return null;
    }

    const queueItem = {
      key: '0',
      href: queueHref,
      label: COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_OWN_CASES_LABEL
    };

    const correspondenceTable = (org) => {
      return org.name === COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_OWN_CORRESPONDENCE_LABEL ||
      org.name === COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_CORRESPONDENCE_CASES;
    };

    const organizationItems = organizations.map((org, index) => {
      // If the url is a specified path, use it over the organization route
      const orgHref = org.url?.includes('/') ? org.url : `/organizations/${org.url}`;

      const label = correspondenceTable(org) ?
        org.name : sprintf(COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL, org.name);

      return {
        key: (index + 1).toString(),
        href: (location === org.url) ? '#' : orgHref,
        label
      };
    });

    const items = [queueItem, ...organizationItems];

    return <QueueSelectorDropdown items={items} />;
  }
}

QueueOrganizationDropdown.propTypes = {
  organizations: PropTypes.arrayOf(PropTypes.shape({
    name: PropTypes.string.isRequired,
    url: PropTypes.string.isRequired
  }))
};
