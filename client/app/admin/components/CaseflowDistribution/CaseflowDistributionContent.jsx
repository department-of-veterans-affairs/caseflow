// client/app/admin/components/CaseflowDistribution/CaseflowDistributionContent.js

import React from 'react';
import InteractableLeverWrapper from './InteractableLeversWrapper';
import StaticLeverWrapper from './StaticLeversWrapper';
import StaticLever from './StaticLever';
import LeverHistory from './LeverHistory';
import PropTypes from 'prop-types';
import TabWindow from '../../../components/TabWindow';
import ContentSection from '../../../components/ContentSection';
import { sectionSegmentStyling, sectionHeadingStyling, anchorJumpLinkStyling } from '../../../queue/StickyNavContentArea';
import COPY from '../../../../COPY';
import { css } from 'glamor';

// import { connect } from 'react-redux';

let contentTabs = [
  {
    disable: false,
    label: 'Case Distribution',
  },
  {
    disable: true,
    label: 'Veteran Extract',
  }
]

const CaseflowDistributionContent = ({ levers, activeLevers, inactiveLevers, saveChanges, formattedHistory, isAdmin }) => {
  return (
    <div className="cf-app-segment cf-app-segment--alt">
      <h1>{isAdmin ? 'Administration' : 'Non-Admin User'}</h1>
      <div> {/* Main Content Wrapper*/}
        <TabWindow tabs={contentTabs} />
        <h2 >Cast Distribution Algorithm Values</h2>
        <p className="cf-lead-paragraph">The Case Distribution Algorithm determines how cases are assigned to VLJs and their teams.  Current algorithm is “By Docket Date.”</p>
        {/* REPLACE BOTH ABOVE WITH CREATED TEXT IN COPY FILE COPY.XXXXX*/}
        <div id="active-data-elements">  {/* Container for Active Levers*/}
          <h2 {...sectionHeadingStyling}>
            <a id="our-elemnt" {...anchorJumpLinkStyling}>
              {"Active Data Elements"}
              {/* REPLACE WITH CREATED TEXT IN COPY FILE COPY.XXXXX*/}
            </a>
          </h2>
          <div {...sectionSegmentStyling}>
            {/* <InteractableLeverWrapper levers={levers} activeLevers={activeLevers} /> */}
          </div>
        </div>
        <div id="inactive-data-elements">  {/* Container for Active Levers*/}
          <h2 {...sectionHeadingStyling}>
            <a id="our-elemnt" {...anchorJumpLinkStyling}>
              {"Inactive Data Elements"}
              {/* REPLACE WITH CREATED TEXT IN COPY FILE COPY.XXXXX*/}
            </a>
          </h2>
          <div {...sectionSegmentStyling}>
            {/* Temporary Static Lever Implementation before wrapper */}
            <table>
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
              {"Case Distribution Algorithm Change History"}
              {/* REPLACE WITH CREATED TEXT IN COPY FILE COPY.XXXXX*/}
            </a>
          </h2>
          <div {...sectionSegmentStyling}>
            <p className="cf-lead-paragraph">Change history for Case Distribution Admin shows changes made in the last 365 days.</p>
            <LeverHistory historyData={formattedHistory} />
          </div>
        </div>


      </div>


      {/* <InteractableLeverWrapper levers={levers} activeLevers={activeLevers} /> */}
      {/* <StaticLeverWrapper levers={levers} activeLevers={inactiveLevers} /> */}
      {/* cancel and save button component */}
      {/* Other content */}
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

// ...
export default CaseflowDistributionContent;
