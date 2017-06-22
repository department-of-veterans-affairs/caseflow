import React from 'react';
import Banner from 'react-banner';
// import WrenchIcon from '../components/WrenchIcon';
import FoundIcon from '../components/FoundIcon';

/*
 * Caseflow Certification Footer.
 * Shared between all Certification v2 pages.
 * Handles the display of the cancel certiifcation modal.
 *
 */
export default class CaseflowBanner extends React.Component {

  render() {


    return (
      <Banner
        logo={FoundIcon}
        search={false}
        url={ window.location.pathname }
         />
        )
  }
}

