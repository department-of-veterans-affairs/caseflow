import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import moment from 'moment';

import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

import Tooltip from '../../components/Tooltip';
import { DateString } from '../../util/DateUtil';

const listStyling = css({
  listStyle: 'none',
  textAlign: 'left',
  marginBottom: 0,
  padding: 0,
  '& > li': {
    marginBottom: 0,
    '& > strong': {
      color: COLORS.WHITE
    }
  }
});

const IhpDaysWaitingTooltip = (props) => {
  const { requestedAt, receivedAt, children } = props;
  const daysWaitingEndDate = receivedAt ? moment(receivedAt).startOf('day') : moment().startOf('day');
  const requestedAtMoment = moment(requestedAt).startOf('day');
  const daysWaiting = `${daysWaitingEndDate.diff(requestedAtMoment, 'days')} days`;

  const tooltipText = (
    <div>
      <strong>This case has an IHP Request associated with it.</strong>
      <ul {...listStyling}>
        <li><strong>IHP Requested:</strong> <DateString date={requestedAt} /></li>
        <li><strong>IHP Received:</strong> <DateString date={receivedAt} /></li>
        <li><strong>On hold for IHP:</strong> {daysWaiting}</li>
      </ul>
    </div>
  );

  return <Tooltip text={tooltipText} position="bottom" >{children}</Tooltip>;
};

IhpDaysWaitingTooltip.propTypes = {
  receivedAt: PropTypes.string,
  requestedAt: PropTypes.string,
  children: PropTypes.node
};

export default IhpDaysWaitingTooltip;
