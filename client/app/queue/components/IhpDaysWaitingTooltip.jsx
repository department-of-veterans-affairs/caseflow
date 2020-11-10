import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import moment from 'moment';

import Tooltip from '../../components/Tooltip';
import { DateString } from '../../util/DateUtil';

const listStyling = css({
  listStyle: 'none',
  textAlign: 'left',
  padding: 0,
  '& > li': {
    marginBottom: 0
  }
});

// Creates a tool tip that displays information about the status of an appeal's most recent Informal Hearing
// Presentation task. If the ihp task is not complete, days waiting will show how long it has been since the IHP was
// requested. If the ihp task is complete, days waiting will show how long took for the IHP task to be received.
const IhpDaysWaitingTooltip = (props) => {
  const { requestedAt, receivedAt, children } = props;

  if (!requestedAt) {
    return children;
  }

  const today = moment();
  const daysSinceIhpReceived = receivedAt ? `(${today.diff(moment(receivedAt), 'd')} days)` : '';
  const daysWaiting = `${(receivedAt ? moment(receivedAt) : today).diff(moment(requestedAt), 'd')} days`;

  const tooltipText = (
    <div>
      <strong>This case has an IHP Request associated with it.</strong>
      <ul {...listStyling}>
        <li data-testid="ihp-requested">
          <strong>IHP Requested:</strong> <DateString date={requestedAt} />
        </li>
        <li data-testid="ihp-received">
          <strong>IHP Received:</strong> <DateString date={receivedAt} /> {daysSinceIhpReceived}
        </li>
        <li data-testid="ihp-days-waiting">
          <strong>On hold for IHP:</strong> {daysWaiting}
        </li>
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
