import React from 'react';
import WrenchIcon from '../components/WrenchIcon';
import ApiUtil from '../util/ApiUtil';
import * as Constants from './constants/constants';


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
      showBanner: true
    };
  }

  checkDependencies() {
    ApiUtil.get('/dependencies-check').
    then((data) => {
      let outage = JSON.parse(data.text).dependencies_outage;

      this.setState({
        showBanner: outage
      });
    }, () => {
      this.setState({
        showBanner: true
      });
    });
  }

  render() {

    setTimeout(() =>
     this.checkDependencies(), Constants.POLLING_INTERVAL);

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

