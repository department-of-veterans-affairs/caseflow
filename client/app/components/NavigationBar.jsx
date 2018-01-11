import React from 'react';
import PropTypes from 'prop-types';
import DropdownMenu from './DropdownMenu';
import Link from './Link';
import Breadcrumbs from './Breadcrumbs';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';
import CaseflowLogo from './CaseflowLogo';
import { css } from 'glamor';
import { COLORS } from '../util/StyleConstants';

export default class NavigationBar extends React.Component {
  render() {
    const {
      appName,
      defaultUrl,
      dropdownUrls,
      topMessage,
      logoProps,
      userDisplayName
    } = this.props;

    const h1Styling = css({
      margin: 0,
      display: 'inline-block',
      'line-height': '3em',
      fontSize: '1.7rem',
      '& > a': {
        color: COLORS.GREY_DARK,
        paddingLeft: '.3em'
      }
    })

    const pushLeftStyling = css({
      display: 'flex',
      alignItems: 'center'
    })

    return <div><header className="cf-app-header">
      <div>
        <div className="cf-app-width">
          <span className="cf-push-left" {...pushLeftStyling}>
            <CaseflowLogo {...logoProps} />
            <h1 {...h1Styling}>
              <Link id="cf-logo-link" to={defaultUrl}>
                  Caseflow
                <h2 id="page-title" className="cf-application-title">&nbsp; {appName}</h2>
              </Link>
            </h1>
            <Breadcrumbs>
              {this.props.children}
            </Breadcrumbs>
            {topMessage && <h2 className="cf-application-title"> &nbsp; | &nbsp; {topMessage}</h2>}
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
  defaultUrl: PropTypes.string.isRequired,
  userDisplayName: PropTypes.string.isRequired,
  logoName: PropTypes.string.isRequired,
  appName: PropTypes.string.isRequired
};
