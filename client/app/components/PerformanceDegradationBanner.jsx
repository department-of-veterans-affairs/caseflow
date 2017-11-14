import React from 'react';
import WrenchIcon from './WrenchIcon';
import ApiUtil from '../util/ApiUtil';
import * as AppConstants from '../constants/AppConstants';

/*
 * Caseflow Performance Degradation Banner.
 * Shared between all Certification pages.
 * Notifies users if dependencies may be experiencing an outage .
 *
 */
export default class PerformanceDegradationBanner extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showBanner: false,
      isRequesting: false
    };

    this.dependencies = {
      certification: ['BGS.AddressService', 'BGS.OrganizationPoaService', 'BGS.PersonFilenumberService', 'BGS.VeteranService', 'VACOLS', 'VBMS', 'VBMS.FindDocumentSeriesReference'],
      reader: ['VBMS', 'VACOLS'],
      hearing: ['VACOLS'],
      dispatch: ['BGS.BenefitsService', 'VBMS', 'VACOLS'],
      other: ['BGS.AddressService', 'BGS.BenefitsService', 'BGS.ClaimantFlashesService', 'BGS.OrganizationPoaService', 'BGS.PersonFilenumberService', 'BGS.VeteranService', 'VACOLS', 'VBMS', 'VBMS.FindDocumentSeriesReference', 'VVA']
    };
  }

  checkDependencies() {
    // Don't make a subsequent request for dependency check
    // if the first one hasn't returned from the server still
    if (this.state.isRequesting) {
      return;
    }

    this.appName = Object.keys(this.dependencies).filter((key) => {
      return window.location.pathname.includes(key);
    })[0] || 'other';

    this.setState({ isRequesting: true });
    ApiUtil.get('/dependencies-check').
      then((data) => {
        let report = JSON.parse(data.text).dependencies_report;
        // Each app has a relevant report
        let outageAffectingCurrentApp = report.filter((key) => {
          return this.dependencies[this.appName].includes(key);
        });

        this.setState({
          showBanner: Boolean(outageAffectingCurrentApp.length > 0),
          isRequesting: false
        });
      }, () => {
        this.setState({
          showBanner: false,
          isRequesting: false
        });
      });
  }

  componentDidMount() {
    // initial check
    this.checkDependencies();

    // subsequent checks
    this.interval = setInterval(() =>
      this.checkDependencies(), AppConstants.DEPENDENCY_OUTAGE_POLLING_INTERVAL);
  }

  componentWillUnmount() {
    clearInterval(this.interval);
  }

  render() {

    return <div>
      { this.state.showBanner &&
        <div className="usa-banner">
          <div className="usa-grid usa-banner-inner">
            <div className="banner-icon">
              <WrenchIcon />
            </div>
            <span className="banner-text">
              We've detected technical issues in our system.
              You can continue working, though some users may experience delays.
            </span>
          </div>
        </div>
      }
    </div>;
  }
}
