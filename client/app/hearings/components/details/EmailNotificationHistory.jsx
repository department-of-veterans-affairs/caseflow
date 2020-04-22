// Email Notification Table
import PropTypes from 'prop-types';
import React from 'react';
import Accordion from '../../../components/Accordion';
import AccordionSection from '../../../components/AccordionSection';
import Table from '../../../components/Table';
import COPY from '../../../../COPY';
import moment from 'moment-timezone';

export const EmailNotificationHistory = ({ rows }) => (
  <Accordion style="bordered" defaultActiveKey={[COPY.EMAIL_NOTIFICATION_HISTORY_TITLE]}>
    <AccordionSection title={COPY.EMAIL_NOTIFICATION_HISTORY_TITLE}>
      <div>{COPY.EMAIL_NOTIFICATION_HISTORY_INTRO}</div>
      <Table
        columns={[
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
        ]}
        getKeyForRow={(index) => index}
        rowObjects={rows}
      />
    </AccordionSection>
  </Accordion>
);

EmailNotificationHistory.propTypes = {
  rows: PropTypes.shape({
    emailAddress: PropTypes.string,
    sentAt: PropTypes.string,
    sentTo: PropTypes.string,
    sentBy: PropTypes.string
  })
};
