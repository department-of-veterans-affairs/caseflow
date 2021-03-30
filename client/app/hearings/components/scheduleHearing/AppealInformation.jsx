import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { ReadOnly } from '../details/ReadOnly';
import { renderAppealType } from '../../../queue/utils';

export const AppealStreamDetails = ({
  remandSourceAppealId,
  cavcRemand,
  caseType,
  isAdvancedOnDocket,
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
          {cavcRemand.cavc_judge_full_name}
        </div>
      </Link>
    </React.Fragment>
  ) : caseLabel;

};

AppealStreamDetails.propTypes = {
  cavcRemand: PropTypes.object,
  caseType: PropTypes.string,
  remandSourceAppealId: PropTypes.string,
  isAdvancedOnDocket: PropTypes.bool,
};

export const AppealInformation = ({ appeal }) => {
  console.log('APPEAL: ', appeal);

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
        text={<AppealStreamDetails {...appeal} />}
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
        // eslint-disable-next-line camelcase
        text={appeal?.powerOfAttorney?.representative_name}
      />
      {appeal?.veteranDateOfDeath && (
        <ReadOnly
          spacing={15}
          label="Date of Death"
          text={appeal?.veteranDateOfDeath}
        />
      )}
    </div>
  );
};

AppealInformation.propTypes = {
  appeal: PropTypes.object,
};
