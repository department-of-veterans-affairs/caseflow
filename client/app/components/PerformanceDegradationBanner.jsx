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
      showBannerOne: false,
      showBannerTwo: false,
      showBannerThree: false,
      isRequesting: false,
      degradedServices: [],
    };

  }

  checkDependencies() {
    // Don't make a subsequent request for dependency check
    // if the first one hasn't returned from the server still
    if (this.state.isRequesting || document.hidden) {
      return;
    }

    this.setState({ isRequesting: true });
    ApiUtil.get('/dependencies-check').
      then((data) => {
        let report = data.body.dependencies_report;

        this.setState({
          showBannerOne: Boolean(report.length === 1),
          showBannerTwo: Boolean(report.length === 2),
          showBannerThree: Boolean(report.length > 2),
          degradedServices: report,
          isRequesting: false,
        });
      }, () => {
        this.setState({
          showBannerOne: false,
          showBannerTwo: false,
          showBannerThree: false,
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
      { this.state.showBannerOne &&
        <div className="usa-banner">
          <div className="usa-grid usa-banner-inner">
            <div className="banner-icon">
              <WrenchIcon />
            </div>
            <b>{this.state.degradedServices[0]}</b>
            <span className="banner-text">
              is experiencing issues. Caseflow performance and availability may be impacted.
            </span>
          </div>
        </div>
      }
      { this.state.showBannerTwo &&
        <div className="usa-banner">
          <div className="usa-grid usa-banner-inner">
            <div className="banner-icon">
              <WrenchIcon />
            </div>
            <b>{this.state.degradedServices[1]}</b> and <b>{this.state.degradedServices[0]}</b>
            <span className="banner-text">
            are experiencing issues. Caseflow performance and availability may be impacted.
            </span>
          </div>
        </div>
      }
      { this.state.showBannerThree &&
        <div className="usa-banner">
          <div className="usa-grid usa-banner-inner">
            <div className="banner-icon">
              <WrenchIcon />
            </div>
            {this.state.degradedServices.length > 2 &&
            <>
              {this.state.degradedServices.map((item, index) => {
                if (index === this.state.degradedServices.length - 1) {
                  return <span>and <b key={index}>  {item}</b></span>;
                }

                return <b key={index}> {item}, </b>;

              })}
            </>
            }
            <span className="banner-text">
              are experiencing issues. Caseflow performance and availability may be impacted.
            </span>
          </div>
        </div>
      }
    </div>;
  }
}
