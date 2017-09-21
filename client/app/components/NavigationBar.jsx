import React from 'react';
import PropTypes from 'prop-types';
import DropdownMenu from './DropdownMenu';
import Link from './Link';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';
import { Route } from 'react-router-dom';

export default class NavigationBar extends React.Component {
  render() {
    let {
      appName,
      breadcrumbs,
      dropdownUrls,
      userDisplayName
    } = this.props;

    const getRoutes = (element) => {
      if (!element.props.children) {
        return [];
      }

      return React.Children.toArray(element.props.children).reduce((acc, child) => {
        if (child.props.breadcrumb) {
          return [...acc, {
            path: child.props.path,
            breadcrumb: child.props.breadcrumb
          }];
        }

        return [...acc, ...getRoutes(child)];
      }, []);
    };

    const breadcrumbComponents = getRoutes(this).map((route) => <Route path={route.path} render={
      (props) => <span>
          <h2 id="page-title" className="cf-application-title">&nbsp; > &nbsp;</h2>
          <Link id="cf-logo-link" to={props.match.url}>
            <h2 id="page-title" className="cf-application-title">{route.breadcrumb}</h2>
          </Link>
        </span>
      } />
    );

    return <div><header className="cf-app-header">
        <div>
          <div className="cf-app-width">
            <span className="cf-push-left">
              <h1 className={`cf-logo cf-logo-image-${appName.toLowerCase()}`}>
                <Link id="cf-logo-link" to="/">
                  Caseflow
                  <h2 id="page-title" className="cf-application-title">&nbsp; {appName}</h2>
                </Link>
              </h1>
              {breadcrumbComponents}
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
  userDisplayName: PropTypes.string.isRequired,
  appName: PropTypes.string.isRequired
};
