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
      isRequesting: false,
      bgsMessage: false,
      vbmsMessage: false,
      vvaMessage: false,
      vacolsMessage: false,
      govDeliveryMessage: false,
      vaDotGovMessage: false
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
        // Each app has a relevant report

        report.forEach((el) => {
          if (el === 'degraded_service_banner_bgs') {
            this.setState({
              bgsMessage: true
            });
          } else if (el === 'degraded_service_banner_vbms') {
            this.setState({
              vbmsMessage: true
            });
          } else if (el === 'degraded_service_banner_vva') {
            this.setState({
              vvaMessage: true
            });
          } else if (el === 'degraded_service_banner_vacols') {
            this.setState({
              vacolsMessage: true
            });
          } else if (el === 'degraded_service_banner_gov_delivery') {
            this.setState({
              govDeliveryMessage: true
            });
          } else if (el === 'degraded_service_banner_va_dot_gov') {
            this.setState({
              vaDotGovMessage: true
            });
          }
        });
        this.setState({
          showBanner: Boolean(report.length > 0),
          isRequesting: false,
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
            { this.state.bgsMessage && <span className="banner-text">
              BGS: We've detected technical issues in our system.
              You can continue working, though some users may experience delays.
            </span> }
            { this.state.vbmsMessage && <span className="banner-text">
              VBMS: We've detected technical issues in our system.
              You can continue working, though some users may experience delays.
            </span> }
            { this.state.vvaMessage && <span className="banner-text">
              VVA: We've detected technical issues in our system.
              You can continue working, though some users may experience delays.
            </span> }
            { this.state.vacolsMessage && <span className="banner-text">
              VACOLS: We've detected technical issues in our system.
              You can continue working, though some users may experience delays.
            </span> }
            { this.state.govDeliveryMessage && <span className="banner-text">
              GOV Delivery: We've detected technical issues in our system.
              You can continue working, though some users may experience delays.
            </span> }
            { this.state.vaDotGovMessage && <span className="banner-text">
              VA.GOV: We've detected technical issues in our system.
              You can continue working, though some users may experience delays.
            </span> }
          </div>
        </div>
      }
    </div>;
  }
}
