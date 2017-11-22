import React from 'react';
import PropTypes from 'prop-types';
import ChildNavLink from './ChildNavLink';

// To be used with the "StickyNav" component
// This generates the list of links for a side navigation list

export default class NavLink extends React.PureComponent {
  constructor() {
    super();
    this.state = {
      menu: false
    };
  }

  showSubMenu = () => {
    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  }

  render() {
    const { anchor, name, subnav } = this.props;

    return <li>
      <a href={anchor} onClick={this.showSubMenu}>{name}</a>
      {this.state.menu && subnav && <ChildNavLink links={subnav} />}
    </li>;
  }
}

NavLink.propTypes = {
  anchor: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  subnav: PropTypes.array
};
