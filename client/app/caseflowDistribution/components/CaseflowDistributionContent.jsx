import React, { useState, useEffect } from 'react';
import StaticLeversWrapper from './StaticLeversWrapper';
import InteractableLeverWrapper from './InteractableLeversWrapper';
import LeverHistory from './LeverHistory';
import LeverAlertBanner from './LeverAlertBanner';
import PropTypes from 'prop-types';
import {
  sectionSegmentStyling,
  sectionHeadingStyling,
  anchorJumpLinkStyling } from 'app/queue/StickyNavContentArea';
import COPY from '../../../COPY';

const CaseflowDistributionContent = ({
  levers,
  formattedHistory,
  isAdmin,
  leverStore,
  sectionTitles
}) => {
  const [displayAlert, setDisplayAlert] = useState(false);

  useEffect(() => {
    const unsubscribe = leverStore.subscribe(() => {
      const state = leverStore.getState();

      if (state.saveChangesActivated) {
        setDisplayAlert(true);

        setTimeout(() => {
          setDisplayAlert(false);
        }, 10000);
      }
    });

    return () => {
      unsubscribe();
    };
  }, [leverStore]);

  return (
    <div>
      {displayAlert && (
        <LeverAlertBanner
          title={COPY.CASE_DISTRIBUTION_SUCCESSBANNER_TITLE}
          message={COPY.CASE_DISTRIBUTION_SUCCESSBANNER_DETAIL}
          type='success'
        />
      )}
      <h1>Administration</h1>

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
            <InteractableLeverWrapper levers={levers} leverStore={leverStore} isAdmin={isAdmin}
              sectionTitles={sectionTitles} />
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
  leverStore: PropTypes.any.isRequired,
  sectionTitles: PropTypes.array.isRequired
};

export default CaseflowDistributionContent;
