import React from 'react';
import PropTypes from 'prop-types';

import LinkToAppeal from '../assignHearings/LinkToAppeal';
import DocketTypeBadge from '../../../components/DocketTypeBadge';
import MstBadge from 'app/components/badges/MstBadge/MstBadge';
import PactBadge from 'app/components/badges/PactBadge/PactBadge';
import { badgeStyle } from 'app/hearings/components/dailyDocket/style';
import { renderAppealType } from '../../../queue/utils';
import { HearingRequestType } from '../assignHearings/AssignHearingsFields';
import { Dot } from '../../../components/Dot';
import Tooltip from '../../../components/Tooltip';

export const TimeSlotDetail = ({
  issueCount,
  poaName,
  docketName,
  docketNumber,
  label,
  showDetails,
  showType,
  caseType,
  aod,
  appealExternalId,
  readableRequestType,
  itemSpacing,
  constrainWidth,
  hearingDay,
  regionalOffice,
  hearing,
  mstIdentification,
  pactIdentification,
  legacyMstPactIdentification

}) => {
  const issueLabel = issueCount === 1 ? `${issueCount} issue` : `${issueCount} issues`;

  return (
    <React.Fragment>
      {label}
      {showDetails && (
        <div className="time-slot-details" style={constrainWidth && { textOverflow: 'ellipsis', overflow: 'hidden' }}>
          {issueLabel}{' '}
          <Dot spacing={itemSpacing} />{' '}
          <DocketTypeBadge name={docketName} number={docketNumber} />{' '}
          {showType && docketNumber}{' '}
          <Dot spacing={itemSpacing} />{' '}
          {(mstIdentification || legacyMstPactIdentification) &&
          <div
            className ="schedule-veterans-badge-designation-1"
            style={{ display: 'inline-block', justifyContent: 'left', marginLeft: '-1rem' }}>
            <MstBadge appeal={hearing} />
          </div>}
          {(pactIdentification || legacyMstPactIdentification) &&
          <div
            className ="schedule-veterans-badge-designation-2"
            style={{ display: 'inline-block', justifyContent: 'left' }}>
            <PactBadge appeal={hearing} />
          </div>}
          <Dot spacing={itemSpacing} />{' '}
          <Tooltip text={poaName} position="bottom">
            <span>{poaName}</span>
          </Tooltip>
        </div>
      )}
      {showType && (
        <div className="time-slot-details">
          {caseType && (
            <React.Fragment>
              {renderAppealType({ caseType, isAdvancedOnDocket: aod })}{' '}
              <Dot spacing={itemSpacing} />{' '}
            </React.Fragment>
          )}
          <HearingRequestType hearingRequestType={readableRequestType} />{' '}
          <Dot spacing={itemSpacing} />{' '}
          <LinkToAppeal
            appealExternalId={appealExternalId}
            hearingDay={hearingDay}
            regionalOffice={regionalOffice}
          >
            View Case Details
          </LinkToAppeal>
        </div>
      )}
    </React.Fragment>
  );
};

TimeSlotDetail.propTypes = {
  constrainWidth: PropTypes.bool,
  hearingDay: PropTypes.object,
  regionalOffice: PropTypes.string,
  issueCount: PropTypes.number,
  docketName: PropTypes.string,
  caseType: PropTypes.string,
  appealExternalId: PropTypes.string,
  readableRequestType: PropTypes.string,
  label: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  docketNumber: PropTypes.string,
  showDetails: PropTypes.bool,
  showType: PropTypes.bool,
  aod: PropTypes.bool,
  itemSpacing: PropTypes.number,
  poaName: PropTypes.string,
  hearing: PropTypes.object,
  mstIdentification: PropTypes.bool,
  pactIdentification: PropTypes.bool,
  legacyMstPactIdentification: PropTypes.bool
};
