import React from 'react';
import PropTypes from 'prop-types';
import DropdownMenu from './DropdownMenu';
import Link from './Link';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';

export default class NavigationBar extends React.Component {
  render() {
    let {
      appName,
      menuOptions,
      user
    } = this.props;

    return <header className="cf-app-header">
        <div>
          <div className="cf-app-width">
            <span className="cf-push-left">
              <h1 className={`cf-logo cf-logo-image-${appName.toLowerCase()}`}>
                <Link id="cf-logo-link" to="/">
                  Caseflow
                  <h2 id="page-title" className="cf-application-title">&nbsp; {appName}</h2>
                </Link>
              </h1>
            </span>
            <span className="cf-dropdown cf-push-right">
              <DropdownMenu
                analyticsTitle="Navbar"
                options={menuOptions}
                onClick={this.handleMenuClick}
                onBlur={this.handleOnBlur}
                label={user}
                />
            </span>
          </div>
        </div>
        <PerformanceDegradationBanner />
      </header>;
  }
}

NavigationBar.propTypes = {
  menuOptions: PropTypes.arrayOf(PropTypes.shape({
    title: PropTypes.string.isRequired,
    link: PropTypes.string.isRequired,
    target: PropTypes.string
  })),
  user: PropTypes.string.isRequired,
  appName: PropTypes.string.isRequired
};
