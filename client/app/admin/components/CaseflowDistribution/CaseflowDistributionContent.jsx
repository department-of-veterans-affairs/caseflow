// client/app/admin/components/CaseflowDistribution/CaseflowDistributionContent.js

import React from 'react';
import InteractableLeverWrapper from './InteractableLeversWrapper';
import StaticLeversWrapper from './StaticLeversWrapper';
import LeverHistory from './LeverHistory';
import LeverButtonsWrapper from './LeverButtonsWrapper';
import PropTypes from 'prop-types';
import {
  sectionSegmentStyling,
  sectionHeadingStyling,
  anchorJumpLinkStyling } from '../../../queue/StickyNavContentArea';
import COPY from '../../../../COPY';

const CaseflowDistributionContent = ({ levers, activeLevers, staticLevers, saveChanges, formattedHistory, isAdmin, leverStore }) => {
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
            {/* <InteractableLeverWrapper levers={levers} activeLevers={activeLevers} /> */}
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_ACTIVE_LEVERS_DESCRIPTION}</p>
            <LeverButtonsWrapper leverStore={leverStore}/>
          </div>
        </div>

        <div id="inactive-data-elements">  {/* Container for Static Levers*/}
          <h2 {...sectionHeadingStyling}>
            <a id="our-elemnt" {...anchorJumpLinkStyling}>{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_TITLE}</a>
          </h2>
          <div {...sectionSegmentStyling}>
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_DESCRIPTION}</p>
            <StaticLeversWrapper leverList={staticLevers} leverStore={leverStore} />
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
  activeLevers: PropTypes.array.isRequired,
  staticLevers: PropTypes.array.isRequired,
  saveChanges: PropTypes.func.isRequired,
  formattedHistory: PropTypes.array.isRequired,
  isAdmin: PropTypes.bool.isRequired,
  leverStore: PropTypes.any.isRequired
};

export default CaseflowDistributionContent;
