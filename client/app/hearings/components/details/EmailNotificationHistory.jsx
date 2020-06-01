// Email Notification Table
import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment-timezone';

import { Accordion } from '../../../components/Accordion';
import { COLORS } from '../../../constants/AppConstants';
import { genericRow } from './style';
import {
  sectionHeadingStyling,
  sectionSegmentStyling
} from '../../../components/ContentSection';
import AccordionSection from '../../../components/AccordionSection';
import COPY from '../../../../COPY';
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

const accordionContainer = css({
  '& .usa-accordion-button': css(
    {
      backgroundPosition: 'right 2rem center',
      backgroundRepeat: 'no-repeat',
      backgroundSize: '1.5rem',
    },
    sectionHeadingStyling
  ),
  '& .usa-accordion-content > *:first-child': {
    marginTop: 30
  }
})

export const EmailNotificationHistory = ({ rows }) => (
  <div
    className="cf-app-segment"
    id="virtualHearingEmailEvents"
    {...accordionContainer}
  >
    <Accordion
      header={
        <h2>
          {COPY.EMAIL_NOTIFICATION_HISTORY_TITLE}
        </h2>
      }
      defaultActiveKey={[COPY.EMAIL_NOTIFICATION_HISTORY_TITLE]}
    >
      <AccordionSection
        title={COPY.EMAIL_NOTIFICATION_HISTORY_TITLE}
        {...sectionSegmentStyling}
      >
        <div {...genericRow}>
          {COPY.EMAIL_NOTIFICATION_HISTORY_INTRO}
        </div>
        <div {...genericRow}>
          <Table
            columns={emailColumns}
            getKeyForRow={(index) => index}
            rowObjects={rows}
          />
        </div>
      </AccordionSection>
    </Accordion>
  </div>
);

EmailNotificationHistory.propTypes = {
  rows: PropTypes.shape({
    emailAddress: PropTypes.string,
    sentAt: PropTypes.string,
    sentTo: PropTypes.string,
    sentBy: PropTypes.string
  })
};
