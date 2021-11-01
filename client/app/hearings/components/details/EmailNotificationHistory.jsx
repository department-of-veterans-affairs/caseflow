// Email Notification Table
import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment-timezone';

import { genericRow } from './style';
import Table from '../../../components/Table';

const emailColumns = [
  { align: 'left', valueName: 'sentTo', header: 'Sent To' },
  {
    align: 'left',
    valueName: 'emailAddress',
    header: 'Email Address'
  },
  {
    align: 'left',
    header: 'Date Sent',
    valueFunction: (email) =>
      moment(email.sentAt).
        tz(moment.tz.guess()).
        format('MMM DD, YYYY, h:mm a zz').
        replace(/DT/, 'ST')
  },
  {
    align: 'left',
    valueName: 'sentBy',
    header: 'Sent By'
  }
];

export const EmailNotificationHistory = ({ rows }) => (
  <div id="hearingEmailEvents" {...genericRow}>
    <div className="cf-help-divider" />

    <Table
      columns={emailColumns}
      getKeyForRow={(index) => index}
      rowObjects={rows}
    />
  </div>
);

EmailNotificationHistory.propTypes = {
  rows: PropTypes.arrayOf(
    PropTypes.shape({
      emailAddress: PropTypes.string,
      sentAt: PropTypes.string,
      sentTo: PropTypes.string,
      sentBy: PropTypes.string
    })
  )
};
