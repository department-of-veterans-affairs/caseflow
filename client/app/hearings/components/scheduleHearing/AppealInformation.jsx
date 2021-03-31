import React from 'react';
import PropTypes from 'prop-types';

import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { ReadOnly } from '../details/ReadOnly';
import { renderAppealType } from '../../../queue/utils';
import { formatDateStr } from '../../../util/DateUtil';

export const AppealInformation = ({ appeal }) => {
  /* eslint-disable camelcase */
  const poaLabel = appeal?.powerOfAttorney?.representative_name ?
    appeal?.powerOfAttorney?.representative_name :
    'No representative';
  /* eslint-enable camelcase */

  return (
    <div className="schedule-veteran-appeals-info">
      <h2>Appeal Information</h2>
      <ReadOnly
        spacing={0}
        label={`${appeal?.appellantIsNotVeteran ? 'Appellant' : 'Veteran'} Name`}
        text={appeal?.appellantIsNotVeteran ? appeal?.appellantFullName : appeal?.veteranFullName}
      />
      <ReadOnly spacing={15} label="Issues" text={appeal?.issueCount} />
      <ReadOnly
        className="schedule-veteran-appeals-info-stream"
        spacing={15}
        label="Appeal Stream"
        text={renderAppealType({
          caseType: appeal?.caseType,
          isAdvancedOnDocket: appeal?.isAdvancedOnDocket,
        })}
      />
      <ReadOnly
        spacing={15}
        label="Docket Number"
        text={
          <span>
            <DocketTypeBadge
              name={appeal?.docketName}
              number={appeal?.docketNumber}
            />
            {appeal?.docketNumber}
          </span>
        }
      />
      <ReadOnly
        spacing={15}
        label="Power of Attorney"
        text={poaLabel}
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
};
