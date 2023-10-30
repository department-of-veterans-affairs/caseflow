// client/app/admin/components/CaseflowDistribution/CaseflowDistributionContent.js

import React from 'react';
import InteractableLeverWrapper from './InteractableLeversWrapper';
import StaticLeverWrapper from './StaticLeversWrapper';
import StaticLever from './StaticLever';
import LeverHistory from './LeverHistory';
import PropTypes from 'prop-types';
import ContentSection from '../../../components/ContentSection';
import { sectionSegmentStyling, sectionHeadingStyling, anchorJumpLinkStyling } from '../../../queue/StickyNavContentArea';
import COPY from '../../../../COPY';
import { css } from 'glamor';

// import { connect } from 'react-redux';

const tableHeaderStyling = css({
  borderLeft: '0',
  borderRight: '0',
  borderTop: '0',
  borderColor: '#d6d7d9;',
  fontFamily: 'Source Sans Pro',
  fontWeight: '700',
  fontSize: '19px',
  lineHeight: '1.3em/25px'
});

const tableStyling = css({
  width: '100%',
  tablelayout: 'fixed'
});

const CaseflowDistributionContent = ({ levers, activeLevers, inactiveLevers, saveChanges, formattedHistory, isAdmin }) => {
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
          </div>
        </div>

        <div id="inactive-data-elements">  {/* Container for Static Levers*/}
          <h2 {...sectionHeadingStyling}>
            <a id="our-elemnt" {...anchorJumpLinkStyling}>{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_TITLE}</a>
          </h2>
          <div {...sectionSegmentStyling}>
            {/* Temporary Static Lever Implementation before wrapper */}
            <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_DESCRIPTION}</p>
            <table {...tableStyling}>
              <th {...tableHeaderStyling}>Data Elements</th>
              <th {...tableHeaderStyling}>Values</th>
              <tbody>
                <tr>
                  <StaticLever key={levers[0].item} lever={levers[0]} />
                  <StaticLever key={levers[1].item} lever={levers[1]} />
                  <StaticLever key={levers[2].item} lever={levers[2]} />
                  <StaticLever key={levers[3].item} lever={levers[3]} />
                </tr>
              </tbody>
            </table>
            {/* <StaticLeverWrapper levers={levers} activeLevers={inactiveLevers} /> */}
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


      {/* <InteractableLeverWrapper levers={levers} activeLevers={activeLevers} /> */}
      {/* <StaticLeverWrapper levers={levers} activeLevers={inactiveLevers} /> */}
      {/* cancel and save button component */}
    </div>
  );
};

CaseflowDistributionContent.propTypes = {
  levers: PropTypes.array.isRequired,
  activeLevers: PropTypes.array.isRequired,
  inactiveLevers: PropTypes.array.isRequired,
  saveChanges: PropTypes.func.isRequired,
  formattedHistory: PropTypes.array.isRequired,
  isAdmin: PropTypes.bool.isRequired
};

export default CaseflowDistributionContent;
