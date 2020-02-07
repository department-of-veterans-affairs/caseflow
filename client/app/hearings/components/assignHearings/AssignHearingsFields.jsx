import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { getTime, getTimeInDifferentTimeZone } from '../../../util/DateUtil';
import DocketTypeBadge from '../../../components/DocketTypeBadge';

export const HearingTime = ({ hearing, isCentralOffice }) => {
  const { date, regionalOfficeTimezone } = hearing;

  if (isCentralOffice) {
    return <div>{getTime(date)} </div>;
  }

  return <div>
    {getTime(date)} /<br />{getTimeInDifferentTimeZone(date, regionalOfficeTimezone)}
  </div>;
};

HearingTime.propTypes = {
  hearing: PropTypes.shape({
    date: PropTypes.string,
    regionalOfficeTimezone: PropTypes.string
  }),
  isCentralOffice: PropTypes.bool
};

export const HearingAppellantName = ({ hearing }) => {
  let { appellantFirstName, appellantLastName, veteranFirstName, veteranLastName, veteranFileNumber } = hearing;

  let appellantName;

  if (appellantFirstName && appellantLastName) {
    appellantName = `${appellantFirstName} ${appellantLastName} | ${veteranFileNumber}`;
  } else if (veteranFirstName && veteranLastName) {
    appellantName = `${veteranFirstName} ${veteranLastName} | ${veteranFileNumber}`;
  } else {
    appellantName = veteranFileNumber;
  }

  return <React.Fragment>{appellantName}</React.Fragment>;
};

HearingAppellantName.propTypes = {
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

  if (appeal.attributes.appellantFullName) {
    caseDetails = `${appeal.attributes.appellantFullName} | ${appeal.attributes.veteranFileNumber}`;
  } else {
    caseDetails = `${appeal.attributes.veteranFullName} | ${appeal.attributes.veteranFileNumber}`;
  }

  return <React.Fragment>{caseDetails}</React.Fragment>;
};

CaseDetailsInformation.propTypes = {
  appeal: PropTypes.shape({
    attributes: PropTypes.shape({
      appellantFullName: PropTypes.string,
      veteranFullName: PropTypes.string,
      veteranFileNumber: PropTypes.string
    })
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
    docketNumber: PropTypes.string
  })
};

export const AppealDocketTag = ({ appeal }) => {
  if (appeal.attributes.docketNumber) {
    return <div>
      <DocketTypeBadge name={appeal.attributes.docketName} number={appeal.attributes.docketNumber} />
      {appeal.attributes.docketNumber}
    </div>;
  }

  return null;
};

AppealDocketTag.propTypes = {
  appeal: PropTypes.shape({
    attributes: PropTypes.shape({
      docketName: PropTypes.string,
      docketNumber: PropTypes.string
    })
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
