import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';

import { HearingTime } from '../HearingTime';
import { PreppedCheckbox } from './DailyDocketRowInputs';
import COPY from '../../../../COPY';
import DocketTypeBadge from '../../../components/DocketTypeBadge';

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
  paperCase: PropTypes.bool
});

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

export default class HearingText extends React.Component {
  render () {
    const { hearing, index, user, update, readOnly, initialState } = this.props;

    return <React.Fragment>
      <div>{user.userHasHearingPrepRole &&
        <PreppedCheckbox hearing={hearing} update={update} readOnly={readOnly} />}
      </div>
      <div><strong>{index + 1}</strong></div>
      <AppellantInformation hearing={hearing} />
      <HearingTime hearing={initialState} showIssueCount showRegionalOffice showRequestType />
    </React.Fragment>;
  }
}

HearingText.propTypes = {
  hearing: hearingPropTypes,
  index: PropTypes.number,
  user: PropTypes.shape({
    userHasHearingPrepRole: PropTypes.bool
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool,
  initialState: PropTypes.object
};
