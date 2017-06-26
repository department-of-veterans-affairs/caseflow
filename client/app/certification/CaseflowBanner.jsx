import React from 'react';
import WrenchIcon from '../components/WrenchIcon';
// import FoundIcon from '../components/FoundIcon';

/*
 * Caseflow Certification Footer.
 * Shared between all Certification v2 pages.
 * Handles the display of the cancel certiifcation modal.
 *
 */
export default class CaseflowBanner extends React.Component {

  render() {


    return (
      <div className="usa-banner">
        <div className="usa-grid usa-banner-inner">
          <div className="banner-icon">
            <WrenchIcon/>
          </div>
          <span className="banner-text">We've detected technical issues in our system. You can continue working,
          though some users may experience delays.
          </span>
        </div>
      </div>
    );
  }
}

