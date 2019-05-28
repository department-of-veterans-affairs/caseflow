import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import DocketTypeBadge from '../../../components/DocketTypeBadge';

import { PreppedCheckbox } from './DailyDocketRowInputs';

import moment from 'moment';

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
    {hearing.docketNumber}
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

export default class DisplayText extends React.Component {
  render () {
    const { hearing, index, user, update, readOnly, initialState } = this.props;

    return <React.Fragment>
      <div>{user.userRoleHearingPrep &&
        <PreppedCheckbox hearing={hearing} update={update} readOnly={readOnly} />}
      </div>
      <div><strong>{index + 1}</strong></div>
      <AppellantInformation hearing={hearing} />
      <HearingTime hearing={initialState} />
    </React.Fragment>;
  }
}
