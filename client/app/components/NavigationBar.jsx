import React from 'react';
import PropTypes from 'prop-types';
import DropdownMenu from './DropdownMenu';
import Link from './Link';

export default class NavigationBar extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      menu: false
    };
  }

  handleMenuClick = () => {
    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  };

  render() {
    let {
      appName,
      color,
      menuOptions,
      user
    } = this.props;

    return <div>
        <div className="cf-app-width">
          <span class="cf-push-left">
            <h1 className={`cf-logo cf-logo-image-${appName.toLowerCase()}`}>
              <Link id="cf-logo-link" to="/">Caseflow</Link>
            </h1>
            <h2 id="page-title" className="cf-application-title">&nbsp; &nbsp; {appName}</h2>
          </span>
          <span className="cf-dropdown cf-push-right">
            <DropdownMenu
              options={menuOptions}
              onClick={this.handleMenuClick}
              onBlur={this.handleMenuClick}
              label={user}
              menu={this.state.menu}
              />
          </span>
        </div>
      </div>;
  }
}

NavigationBar.propTypes = {
  menuOptions: PropTypes.arrayOf(PropTypes.shape({
    title: PropTypes.string.isRequired,
    link: PropTypes.string.isRequired
  })),
  user: PropTypes.string.isRequired,
  appName: PropTypes.string.isRequired
};
