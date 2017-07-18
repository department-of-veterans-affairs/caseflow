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
      showBanner: false
    };
  }

  checkDependencies() {
    ApiUtil.get('/dependencies-check').
    then((data) => {
      let outage = JSON.parse(data.text).dependencies_outage;

      this.setState({
        showBanner: Boolean(outage)
      });
    }, () => {
      this.setState({
        showBanner: true
      });
    });
  }

  componentDidMount() {
    // initial check
    this.checkDependencies();
  }

  componentDidUpdate() {
    // subsequent checks
    setTimeout(() =>
     this.checkDependencies(), AppConstants.DEPENDENCY_OUTAGE_POLLING_INTERVAL);
  }

  render() {

    return <div>
      { this.state.showBanner &&
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
      }
      </div>;
  }
}

