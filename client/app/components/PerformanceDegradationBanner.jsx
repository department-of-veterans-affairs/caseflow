import React from 'react';
import WrenchIcon from './WrenchIcon';
import ApiUtil from '../util/ApiUtil';
import { listWithOxfordComma } from '../util/banner/format';
import COPY from '../../COPY';
import * as AppConstants from '../constants/AppConstants';

/*
 * Caseflow Performance Degradation Banner.
 * Shared between all Certification pages.
 * Notifies users if dependencies may be experiencing an outage .
 * Updated to display one ore more systems when experiencing outages.
 */
export default class PerformanceDegradationBanner extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      isRequesting: false,
      services: [],
    };
  }

  // generates banner text prefix by formatting the services list for proper grammar
  getBannerTextPrefix() {
    const { services } = this.state;

    // formats a list following oxford comma grammar
    return listWithOxfordComma(services);
  }

  // formats banner text suffix with proper grammer
  formatBannerTextSuffix(services) {
    return this.suffix = (services.length > 1 ? COPY.DEGRADED_SYSTEM_PLURAL : COPY.DEGRADED_SYSTEM_SINGULAR);

  }

  // generates banner text suffix with proper grammar
  getBannerTextSuffix() {
    const { services } = this.state;

    return this.formatBannerTextSuffix(services);
  }

  // generates banner text
  getBannerText() {
    return (
      <span className="banner-text">
        <b>{this.getBannerTextPrefix()}</b> {this.getBannerTextSuffix()}
      </span>
    );
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
          services: report,
          isRequesting: false,
        });
      }, () => {
        this.setState({
          services: [],
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
      {this.state.services.length > 0 &&
        <div className="usa-banner">
          <div className="usa-grid usa-banner-inner">
            <div className="banner-icon">
              <WrenchIcon />
            </div>
            {this.getBannerText()}
          </div>
        </div>
      }
    </div>;
  }
}
