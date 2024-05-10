import React from 'react';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
// import { useLocation } from 'react-router-dom';
import QueueSelectorDropdown from './QueueSelectorDropdown';
import COPY from '../../../COPY';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';

export default class QueueOrganizationDropdown extends React.Component {
  render = () => {
    const { organizations } = this.props;
    const { isInboundOpsTeamUser } = this.props;
    const { isMailSupervisor } = this.props;
    const { isInboundOpsSuperuser } = this.props;
    const url = window.location.pathname.split('/');
    const location = url[url.length - 1];
    const queueHref = (location === 'queue') ? '#' : '/queue';
    let correspondenceItems = {};

    const isMailTeamAffiliated = () => {
      if (isInboundOpsSuperuser || isMailSupervisor || isInboundOpsTeamUser) {
        return true;
      }

      return false;
    };

    if (organizations.length < 1 && !isMailTeamAffiliated()) {
      return null;
    }

    const queueItem = {
      key: '0',
      href: queueHref,
      label: COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_OWN_CASES_LABEL
    };

    const organizationItems = organizations.map((org, index) => {
      // If the url is a specified path, use it over the organization route
      const orgHref = org.url.includes('/') ? org.url : `/organizations/${org.url}`;

      return {
        key: (index + 1).toString(),
        href: (location === org.url) ? '#' : orgHref,
        label: sprintf(COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL, org.name)
      };
    });

    let items = [queueItem, ...organizationItems];

    if (isInboundOpsSuperuser === true || isMailSupervisor === true) {
      const orgHref = '/queue/correspondence/team';

      correspondenceItems = {
        key: (2).toString(),
        href: orgHref,
        label: sprintf(QUEUE_CONFIG.CASE_LIST_TABLE_QUEUE_DROPDOWN_CORRESPONDENCE_CASES)
      };

      items = [...items, correspondenceItems];
    }
    if (isInboundOpsTeamUser === true) {
      const orgHref = '/queue/correspondence';

      correspondenceItems = {
        key: (2).toString(),
        href: orgHref,
        label: sprintf(QUEUE_CONFIG.CASE_LIST_TABLE_QUEUE_DROPDOWN_OWN_CORRESPONDENCE_LABEL)
      };
      // This places the "Your Correspondence" option at the 2nd(1) index
      const items1 = items.slice(0, 1);
      const items2 = items.slice(1);

      items = [...items1, correspondenceItems, ...items2];
    }

    return <QueueSelectorDropdown items={items} />;
  }
}

QueueOrganizationDropdown.propTypes = {
  isMailTeamUser: PropTypes.bool,
  isInboundOpsTeamUser: PropTypes.bool,
  isMailSupervisor: PropTypes.bool,
  isInboundOpsSuperuser: PropTypes.bool,
  organizations: PropTypes.arrayOf(PropTypes.shape({
    name: PropTypes.string.isRequired,
    url: PropTypes.string.isRequired
  })),
};
