import React from 'react';
import StaticLeversWrapper from './StaticLeversWrapper';
import LeverHistory from './LeverHistory';
import LeverButtonsWrapper from './LeverButtonsWrapper';
import BatchSize from './BatchSize';
import DocketTimeGoals from './DocketTimeGoals';
import AffinityDays from './AffinityDays';
import ExclusionTable from './ExclusionTable';
import PropTypes from 'prop-types';
import {
  sectionSegmentStyling,
  sectionHeadingStyling,
  anchorJumpLinkStyling } from '../../../queue/StickyNavContentArea';
import COPY from '../../../../COPY';

const CaseflowDistributionContent = ({ levers, saveChanges, formattedHistory, isAdmin, leverStore }) => {
  return (
    <div className="cf-app-segment cf-app-segment--alt">
      <h1>{isAdmin ? 'Administration' : 'Non-Admin User'}</h1>

      <div> {/* Main Content Wrapper*/}
        <h2>{COPY.CASE_DISTRIBUTION_TITLE}</h2>
        <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_ALGORITHM_DESCRIPTION}</p>

        <div id="active-data-elements">  {/* Container for Active Levers*/}
          <h2 {...sectionHeadingStyling}>
            <a id="our-elemnt" {...anchorJumpLinkStyling}>{COPY.CASE_DISTRIBUTION_ACTIVE_LEVERS_TITLE}</a>
          </h2>
          <div {...sectionSegmentStyling}>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_ACTIVE_LEVERS_DESCRIPTION}</p>
            <div className="cf-help-divider"></div>
            <h2>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_TITLE}</h2>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_DESCRIPTION}</p>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_DESCRIPTION_NOTE}</p>
            <ExclusionTable />
            <BatchSize leverList={levers.batchSizeLevers} leverStore={leverStore} />
            <AffinityDays leverList={levers.affinityLevers} leverStore={leverStore} />
            <DocketTimeGoals leverList={levers.docketLevers} leverStore={leverStore} />
            <LeverButtonsWrapper leverStore={leverStore} />
          </div>
        </div>

        <div id="inactive-data-elements">  {/* Container for Static Levers*/}
          <h2 {...sectionHeadingStyling}>
            <a id="our-elemnt" {...anchorJumpLinkStyling}>{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_TITLE}</a>
          </h2>
          <div {...sectionSegmentStyling}>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_DESCRIPTION}</p>
            <StaticLeversWrapper leverList={levers.staticLevers} leverStore={leverStore} />
          </div>
        </div>

        <div id="case-distribution-history">  {/* Container for Active Levers*/}
          <h2 {...sectionHeadingStyling}>
            <a id="our-elemnt" {...anchorJumpLinkStyling}>
              {COPY.CASE_DISTRIBUTION_HISTORY_TITLE}
            </a>
          </h2>
          <div {...sectionSegmentStyling}>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_HISTORY_DESCRIPTION}</p>
            <LeverHistory historyData={formattedHistory} />
          </div>
        </div>
      </div>
    </div>
  );
};

CaseflowDistributionContent.propTypes = {
  levers: PropTypes.array.isRequired,
  saveChanges: PropTypes.func.isRequired,
  formattedHistory: PropTypes.array.isRequired,
  isAdmin: PropTypes.bool.isRequired,
  leverStore: PropTypes.any.isRequired
};

export default CaseflowDistributionContent;
