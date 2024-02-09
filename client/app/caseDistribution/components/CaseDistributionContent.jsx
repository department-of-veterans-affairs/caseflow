import React from 'react';
import StaticLeversWrapper from './StaticLeversWrapper';
import InteractableLeverWrapper from './InteractableLeversWrapper';
import LeverHistory from './LeverHistory';
import {
  sectionSegmentStyling,
  sectionHeadingStyling,
  anchorJumpLinkStyling } from 'app/queue/StickyNavContentArea';
import COPY from '../../../COPY';

const CaseDistributionContent = () => {

  return (
    <div>
      <h1>{COPY.CASE_DISTRIBUTION_CONTENT_TITLE_H1_TITLE}</h1>

      <div> {/* Main Content Wrapper*/}
        <h2>{COPY.CASE_DISTRIBUTION_TITLE}</h2>
        <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_ALGORITHM_DESCRIPTION}</p>

        <div className="active-data-content" id="active-data-elements">  {/* Container for Active Levers*/}
          <h2 {...sectionHeadingStyling}>
            <span id="our-elemnt" {...anchorJumpLinkStyling}>{COPY.CASE_DISTRIBUTION_ACTIVE_LEVERS_TITLE}</span>
          </h2>
          <div {...sectionSegmentStyling}>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_ACTIVE_LEVERS_DESCRIPTION}</p>
            <div className="cf-help-divider"></div>
            <h2>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_TITLE}</h2>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_DESCRIPTION}</p>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_DESCRIPTION_NOTE}</p>
            <InteractableLeverWrapper />
          </div>
        </div>

        <div className="inactive-data-content" id="inactive-data-elements">  {/* Container for Static Levers*/}
          <h2 {...sectionHeadingStyling}>
            <span id="our-elemnt" {...anchorJumpLinkStyling}>{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_TITLE}</span>
          </h2>
          <div {...sectionSegmentStyling}>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_DESCRIPTION}</p>
            <StaticLeversWrapper />
          </div>
        </div>

        {/* Container for Active Levers*/}
        <div className="case-distribution-history-content" id="case-distribution-history">
          <h2 {...sectionHeadingStyling}>
            <span id="our-elemnt" {...anchorJumpLinkStyling}>
              {COPY.CASE_DISTRIBUTION_HISTORY_TITLE}
            </span>
          </h2>
          <div {...sectionSegmentStyling}>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_HISTORY_DESCRIPTION}</p>
            <LeverHistory />
          </div>
        </div>
      </div>
    </div>
  );
};

export default CaseDistributionContent;
