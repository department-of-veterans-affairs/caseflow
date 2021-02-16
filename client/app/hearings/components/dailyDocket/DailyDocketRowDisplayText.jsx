import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';

import { HearingTime } from '../HearingTime';
import { PreppedCheckbox } from './DailyDocketRowInputs';
import COPY from '../../../../COPY';
import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { PowerOfAttorneyName } from '../../../queue/PowerOfAttorneyDetail';

//import HearingsFnodBadge from '../HearingsFnodBadge';
import FnodBadge from '../../../queue/components/FnodBadge';
import { tooltipListStyling } from '../../../queue/components/style';
import { DateString } from '../../../util/DateUtil';

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
    <FnodBadge
      veteranAppellantDeceased={true}
      uniqueId={14}
      show={true}
      tooltipText = {
        <div>
          <strong>Date of Death Reported</strong>
          <ul {...tooltipListStyling}>
            <li><strong>Veteran: </strong>{'Jones Bill'}</li>
            <li><strong>Source: </strong>{COPY.FNOD_SOURCE}</li>
            <li><strong>Date of Death: </strong><DateString date={'2020-04-05'} /></li>
            <li><strong>Reported on: </strong><DateString date={'2020-04-05'} /></li>
          </ul>
        </div>
      }
    />
    <br /><br />
    {hearing.appellantAddressLine1}<br />
    {hearing.appellantCity ?
      `${hearing.appellantCity} ${hearing.appellantState} ${hearing.appellantZip}` :
      <div>Loading address...</div>}
    <br /><br />
    <PowerOfAttorneyName appealId={hearing.appealExternalId} />
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
