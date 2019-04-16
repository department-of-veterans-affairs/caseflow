import React from 'react';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { getTime, getTimeInDifferentTimeZone } from '../../util/DateUtil';

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
  if (hearing.readableRequestType === 'Central') {
    return <div>{getTime(hearing.scheduledFor)} <br />
      {hearing.regionalOfficeName}
    </div>;
  }

  return <div>{getTime(hearing.scheduledFor)} /<br />
    {getTimeInDifferentTimeZone(hearing.scheduledFor, hearing.regionalOfficeTimezone)} <br />
    {hearing.regionalOfficeName}
    <p>{hearing.currentIssueCount} issues</p>
  </div>;
};

export default class DisplayText extends React.Component {
  render () {
    const { hearing, index } = this.props;

    return <React.Fragment>
      <div><strong>{index + 1}</strong></div>
      <AppellantInformation hearing={hearing} />
      <HearingTime hearing={hearing} />
    </React.Fragment>;
  }
}
