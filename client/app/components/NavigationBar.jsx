import React from 'react';
import PropTypes from 'prop-types';
import DropdownMenu from './DropdownMenu';
import Link from './Link';
import Breadcrumbs from './Breadcrumbs';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';

const CLASS_NAME_MAPPING = {
  default: ' cf-logo cf-logo-image-default',
  certification: 'cf-logo cf-logo-image-certification',
  reader: 'cf-logo cf-logo-image-reader',
  hearingPrep: 'cf-logo cf-logo-image-hearing-prep',
  feedback: 'cf-logo cf-logo-image-feedback',
  efolder: 'cf-logo cf-logo-image-efolder',
  dispatch: 'cf-logo cf-logo-image-dispatch'
};

export default class NavigationBar extends React.Component {
  render() {
    const {
      appName,
      defaultUrl,
      dropdownUrls,
      topMessage,
      userDisplayName
    } = this.props;

    return <div><header className="cf-app-header">
        <div>
          <div className="cf-app-width">
            <span className="cf-push-left">
              <h1 className={CLASS_NAME_MAPPING[appName.split(' ').
                  join('-').
                  toLowerCase()]}>
                <Link id="cf-logo-link" to={defaultUrl}>
                  Caseflow
                  <h2 id="page-title" className="cf-application-title">&nbsp; {appName}</h2>
                </Link>
              </h1>
              <Breadcrumbs>
                {this.props.children}
              </Breadcrumbs>
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
        <PerformanceDegradationBanner />
      </div>
      </header>
      {this.props.children}
    </div>;
  }
}

NavigationBar.propTypes = {
  dropdownUrls: PropTypes.arrayOf(PropTypes.shape({
    title: PropTypes.string.isRequired,
    link: PropTypes.string.isRequired,
    target: PropTypes.string
  })),
  defaultUrl: PropTypes.string.isRequired,
  userDisplayName: PropTypes.string.isRequired,
  appName: PropTypes.string.isRequired
};
