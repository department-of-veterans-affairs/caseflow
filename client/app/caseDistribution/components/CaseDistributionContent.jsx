import React from 'react';
import StaticLeversWrapper from './StaticLeversWrapper';
import InteractableLeverWrapper from './InteractableLeversWrapper';
import PropTypes from 'prop-types';
import {
  sectionSegmentStyling,
  sectionHeadingStyling,
  anchorJumpLinkStyling } from 'app/queue/StickyNavContentArea';
import COPY from '../../../COPY';

const CaseDistributionContent = ({
  levers,
  isAdmin,
  leverStore,
  sectionTitles
}) => {

  return (
    <div>
      <h1>{COPY.CASE_DISTRIBUTION_CONTENT_TITLE_H1_TITLE}</h1>

      <div> {/* Main Content Wrapper*/}
        <h2>{COPY.CASE_DISTRIBUTION_TITLE}</h2>
        <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_ALGORITHM_DESCRIPTION}</p>

        <div id="active-data-elements">  {/* Container for Active Levers*/}
          <h2 {...sectionHeadingStyling}>
            <span id="our-elemnt" {...anchorJumpLinkStyling}>{COPY.CASE_DISTRIBUTION_ACTIVE_LEVERS_TITLE}</span>
          </h2>
          <div {...sectionSegmentStyling}>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_ACTIVE_LEVERS_DESCRIPTION}</p>
            <div className="cf-help-divider"></div>
            <h2>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_TITLE}</h2>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_DESCRIPTION}</p>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_DESCRIPTION_NOTE}</p>
            <InteractableLeverWrapper levers={levers} leverStore={leverStore} isAdmin={isAdmin}
              sectionTitles={sectionTitles} />
          </div>
        </div>

        <div id="inactive-data-elements">  {/* Container for Static Levers*/}
          <h2 {...sectionHeadingStyling}>
            <span id="our-elemnt" {...anchorJumpLinkStyling}>{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_TITLE}</span>
          </h2>
          <div {...sectionSegmentStyling}>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_DESCRIPTION}</p>
            <StaticLeversWrapper leverList={levers.staticLevers} leverStore={leverStore} />
          </div>
        </div>

        <div id="case-distribution-history">  {/* Container for Active Levers*/}
          <h2 {...sectionHeadingStyling}>
            <span id="our-elemnt" {...anchorJumpLinkStyling}>
              {COPY.CASE_DISTRIBUTION_HISTORY_TITLE}
            </span>
          </h2>
          <div {...sectionSegmentStyling}>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_HISTORY_DESCRIPTION}</p>

          </div>
        </div>
      </div>
    </div>
  );
};

CaseDistributionContent.propTypes = {
  levers: PropTypes.object.isRequired,
  isAdmin: PropTypes.bool.isRequired,
  leverStore: PropTypes.any.isRequired,
  sectionTitles: PropTypes.array.isRequired,
};

export default CaseDistributionContent;
