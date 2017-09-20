import React from 'react';
import PropTypes from 'prop-types';
import DropdownMenu from './DropdownMenu';
import Link from './Link';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';

export default class NavigationBar extends React.Component {
  render() {
    let {
      appName,
      breadCrumb,
      defaultUrl,
      dropdownUrls,
      userDisplayName
    } = this.props;

    return <header className="cf-app-header">
        <div>
          <div className="cf-app-width">
            <span className="cf-push-left">
              <h1 className={`cf-logo cf-logo-image-${appName.
                  split(' ').
                  join('-').
                  toLowerCase()}`}>
                <Link id="cf-logo-link" to={defaultUrl}>
                  Caseflow
                  <h2 id="page-title" className="cf-application-title">&nbsp; {appName} {breadCrumb}</h2>
                </Link>
              </h1>
            </span>
            <span className="cf-dropdown cf-push-right">
              <DropdownMenu
                analyticsTitle={`${appName} Navbar`}
                options={dropdownUrls}
                onClick={this.handleMenuClick}
                onBlur={this.handleOnBlur}
                label={userDisplayName}
                />
            </span>
          </div>
        </div>
        <PerformanceDegradationBanner />
      </header>;
  }
}

NavigationBar.propTypes = {
  dropdownUrls: PropTypes.arrayOf(PropTypes.shape({
    title: PropTypes.string.isRequired,
    link: PropTypes.string.isRequired,
    target: PropTypes.string
  })),
  userDisplayName: PropTypes.string.isRequired,
  appName: PropTypes.string.isRequired,
  defaultUrl: PropTypes.string.isRequired,
  breadCrumb: PropTypes.node
};
