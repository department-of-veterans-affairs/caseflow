import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { ReadOnly } from '../details/ReadOnly';
import { AddressLine } from '../details/Address';
import { renderAppealType } from '../../../queue/utils';
import { formatDateStr } from '../../../util/DateUtil';

export const AppealStreamDetails = ({
  remandSourceAppealId,
  cavcRemand,
  caseType,
  isAdvancedOnDocket,
  remandJudgeName
}) => {
  const caseLabel = renderAppealType({
    caseType,
    isAdvancedOnDocket,
  });

  return cavcRemand ? (
    <React.Fragment>
      <span>
        {caseLabel},
      </span>
      <Link href={`/queue/appeals/${remandSourceAppealId}`} >
        <span>
          {caseType}
        </span>
        <div>
          VLJ {remandJudgeName}
        </div>
      </Link>
    </React.Fragment>
  ) : caseLabel;
};

AppealStreamDetails.propTypes = {
  cavcRemand: PropTypes.object,
  caseType: PropTypes.string,
  remandSourceAppealId: PropTypes.string,
  remandJudgeName: PropTypes.string,
  isAdvancedOnDocket: PropTypes.bool,
};

export const AppealInformation = ({ appeal, hearing }) => {
  /* eslint-disable camelcase */
  const poaText = appeal?.powerOfAttorney?.representative_name ?
    appeal?.powerOfAttorney?.representative_name :
    'No representative';
  const appellantName = appeal?.appellantIsNotVeteran ? appeal?.appellantFullName : appeal?.veteranFullName;
  const poaLabel =
    (appeal?.powerOfAttorney?.representative_type && appeal?.powerOfAttorney?.representative_type !== 'Other') ?
      appeal?.powerOfAttorney?.representative_type :
      'Power Of Attorney';

  return (
    <div className="schedule-veteran-appeals-info">
      <h2>{appellantName}</h2>
      <AddressLine
        spacing={5}
        addressLine1={appeal?.appellantAddress?.address_line_1}
        addressState={appeal?.appellantAddress?.state}
        addressCity={appeal?.appellantAddress?.city}
        addressZip={appeal?.appellantAddress?.zip}
      />
      {appeal?.appellantIsNotVeteran && appeal?.appellantRelationship && (
        <ReadOnly
          spacing={15}
          label="Relation to Veteran"
          text={appeal?.appellantRelationship}
        />
      )}
      <ReadOnly spacing={15} label="Issues" text={appeal?.issueCount} />
      <ReadOnly
        className="schedule-veteran-appeals-info-stream"
        spacing={15}
        label="Appeal Stream"
        text={<AppealStreamDetails {...appeal} />}
      />
      <ReadOnly
        unformatted
        className="appeal-information-docket-type-badge"
        spacing={15}
        label="Docket Number"
        text={
          <React.Fragment>
            <DocketTypeBadge
              name={appeal?.docketName}
              number={appeal?.docketNumber}
            />
            {appeal?.docketNumber}
          </React.Fragment>
        }
      />
      <AddressLine
        label={poaLabel}
        name={poaText}
        addressLine1={hearing?.representativeAddress?.addressLine1}
        addressState={hearing?.representativeAddress?.state}
        addressCity={hearing?.representativeAddress?.city}
        addressZip={hearing?.representativeAddress?.zip}
      />
      {appeal?.veteranDateOfDeath && (
        <ReadOnly
          spacing={15}
          label="Date of Death"
          text={formatDateStr(appeal.veteranDateOfDeath)}
        />
      )}
    </div>
  );
};

AppealInformation.propTypes = {
  appeal: PropTypes.object,
  appellantTitle: PropTypes.string,
  hearing: PropTypes.object
};

/* eslint-enable camelcase */
