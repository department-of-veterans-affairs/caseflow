import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import DocketTypeBadge from '../../../components/DocketTypeBadge';

import { PreppedCheckbox } from './DailyDocketRowInputs';
import COPY from '../../../../COPY.json';

import moment from 'moment';

const hearingPropTypes = PropTypes.shape({
  appealExternalId: PropTypes.string,
  appellantAddressLine1: PropTypes.string,
  appellantCity: PropTypes.string,
  appellantState: PropTypes.string,
  appellantZip: PropTypes.string,
  docketName: PropTypes.string,
  docketNumber: PropTypes.string,
  representative: PropTypes.string,
  representativeName: PropTypes.any,
  veteranFileNumber: PropTypes.string,
  scheduledTimeString: PropTypes.string,
  regionalOfficeTimezone: PropTypes.string,
  centralOfficeTimeString: PropTypes.string,
  readableRequestType: PropTypes.string,
  regionalOfficeName: PropTypes.string,
  currentIssueCount: PropTypes.number,
  paperCase: PropTypes.bool
});

export const getDisplayTime = (scheduledTimeString, timezone) => {
  const val = scheduledTimeString ? moment(scheduledTimeString, 'HH:mm').format('h:mm a') : '';

  if (timezone) {
    const tz = moment().tz(timezone).
      format('z');

    return `${val} ${tz}`;
  }

  return val;
};

export const getHearingAppellantName = (hearing) => {
  let { appellantFirstName, appellantLastName, veteranFirstName, veteranLastName } = hearing;

  if (appellantFirstName && appellantLastName) {
    return `${appellantFirstName} ${appellantLastName}`;
  }

  return `${veteranFirstName} ${veteranLastName}`;
};

const AppellantInformation = ({ hearing }) => {
  const appellantName = getHearingAppellantName(hearing);

  return <div>
    <strong>{appellantName}</strong><br />
    <strong>
      <Link href={`/queue/appeals/${hearing.appealExternalId}`} name={hearing.veteranFileNumber} >
        {hearing.veteranFileNumber}
      </Link>
    </strong><br />
    <DocketTypeBadge name={hearing.docketName} number={hearing.docketNumber} />
    {hearing.docketNumber} <br />
    {hearing.paperCase && <span>{COPY.IS_PAPER_CASE}</span>}
    <br /><br />
    {hearing.appellantAddressLine1}<br />
    {hearing.appellantCity ?
      `${hearing.appellantCity} ${hearing.appellantState} ${hearing.appellantZip}` :
      <div>Loading address...</div>}
    {hearing.representative ?
      <div>{hearing.representative} <br /> {hearing.representativeName}</div> :
      <div>Loading rep...</div>}
  </div>;
};

AppellantInformation.propTypes = {
  hearing: hearingPropTypes
};

const HearingTime = ({ hearing }) => {
  const localTime = getDisplayTime(
    hearing.scheduledTimeString,
    hearing.regionalOfficeTimezone || 'America/New_York'
  );
  const coTime = getDisplayTime(hearing.centralOfficeTimeString, 'America/New_York');

  if (hearing.readableRequestType === 'Central') {
    return <div>{coTime}<br />
      {hearing.regionalOfficeName}
    </div>;
  }

  return <div>{coTime} /<br />
    {localTime} <br />
    {hearing.regionalOfficeName}
    <p>{hearing.currentIssueCount} issues</p>
  </div>;
};

HearingTime.propTypes = {
  hearing: hearingPropTypes
};

export default class HearingText extends React.Component {
  render () {
    const { hearing, index, user, update, readOnly, initialState } = this.props;

    return <React.Fragment>
      <div>{user.userHasHearingPrepRole &&
        <PreppedCheckbox hearing={hearing} update={update} readOnly={readOnly} />}
      </div>
      <div><strong>{index + 1}</strong></div>
      <AppellantInformation hearing={hearing} />
      <HearingTime hearing={initialState} />
    </React.Fragment>;
  }
}

HearingText.propTypes = {
  hearing: hearingPropTypes,
  index: PropTypes.number,
  user: PropTypes.shape({
    userRoleHearingPrep: PropTypes.bool
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool,
  initialState: PropTypes.object
};