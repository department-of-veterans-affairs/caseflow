import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import DocketTypeBadge from '../../../components/DocketTypeBadge';

export const HearingAppellantName = ({ hearing, spacingCharacter }) => {
  let { appellantFirstName, appellantLastName, veteranFirstName, veteranLastName, veteranFileNumber } = hearing;

  const appellantName = appellantFirstName && appellantLastName && `${appellantFirstName} ${appellantLastName}`;
  const veteranName = veteranFirstName && veteranLastName && `${veteranFirstName} ${veteranLastName}`;
  const spacer = (appellantName || veteranName) && spacingCharacter;

  return <React.Fragment>{appellantName || veteranName || ''} {spacer} {veteranFileNumber}</React.Fragment>;
};

HearingAppellantName.defaultProps = {
  spacingCharacter: '|'
};

HearingAppellantName.propTypes = {
  spacingCharacter: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  hearing: PropTypes.shape({
    appellantFirstName: PropTypes.string,
    appellantLastName: PropTypes.string,
    veteranFirstName: PropTypes.string,
    veteranLastName: PropTypes.string,
    veteranFileNumber: PropTypes.string
  })
};

export const CaseDetailsInformation = ({ appeal }) => {
  let caseDetails;

  if (appeal.appellantFullName) {
    caseDetails = `${appeal.appellantFullName} | ${appeal.veteranFileNumber}`;
  } else {
    caseDetails = `${appeal.veteranFullName} | ${appeal.veteranFileNumber}`;
  }

  return <React.Fragment>{caseDetails}</React.Fragment>;
};

CaseDetailsInformation.propTypes = {
  appeal: PropTypes.shape({
    appellantFullName: PropTypes.string,
    veteranFullName: PropTypes.string,
    veteranFileNumber: PropTypes.string
  })
};

export const HearingDocketTag = ({ hearing }) => {
  if (hearing.docketNumber) {
    return <div>
      <DocketTypeBadge name={hearing.docketName} number={hearing.docketNumber} />
      {hearing.docketNumber}
    </div>;
  }

  return null;
};

HearingDocketTag.propTypes = {
  hearing: PropTypes.shape({
    docketName: PropTypes.string,
    docketNumber: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.string
    ])
  })
};

export const AppealDocketTag = ({ appeal }) => {
  if (appeal.docketNumber) {
    return <div>
      <DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />
      {appeal.docketNumber}
    </div>;
  }

  return null;
};

AppealDocketTag.propTypes = {
  appeal: PropTypes.shape({
    docketName: PropTypes.string,
    docketNumber: PropTypes.string
  })
};

export const SuggestedHearingLocation = ({ suggestedLocation, format }) => {

  if (!suggestedLocation) {
    return null;
  }

  return (
    <React.Fragment>
      <div>{`${format(suggestedLocation)}`}</div>
      {!_.isNil(suggestedLocation.distance) &&
        <div>{`Distance: ${suggestedLocation.distance} miles away`}</div>
      }
    </React.Fragment>
  );
};

SuggestedHearingLocation.propTypes = {
  format: PropTypes.func.isRequired,
  suggestedLocation: PropTypes.shape({
    name: PropTypes.string,
    address: PropTypes.string,
    city: PropTypes.string,
    state: PropTypes.string,
    zipCode: PropTypes.string,
    distance: PropTypes.number,
    classification: PropTypes.string,
    facilityId: PropTypes.string,
    facilityType: PropTypes.string
  })
};

export const HearingRequestType = ({ hearingRequestType, isFormerTravel }) => {
  if (!hearingRequestType) {
    return null;
  }

  return (
    <React.Fragment>
      {isFormerTravel ? <span>{`former Travel, ${hearingRequestType}`}</span> : <span>{hearingRequestType}</span>}
    </React.Fragment>
  );
};

HearingRequestType.propTypes = {
  hearingRequestType: PropTypes.string,
  isFormerTravel: PropTypes.bool
};
