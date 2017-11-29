import React from 'react';
import PropTypes from 'prop-types';
import ChildNavLink from './ChildNavLink';
import classnames from 'classnames';

// To be used with the "StickyNav" component
// This generates the list of links for a side navigation list

export default class NavLink extends React.PureComponent {
  constructor() {
    super();
    this.state = {
      menu: false,
      selected: false
    };
  }

  onClick = () => {
    this.props.setSelected(this.props.index);
  }

  showSelectedClass = () => {
    return classnames({ selected: this.props.index === this.props.selectedIndex });
  }

  render() {
    const { anchor, name, subnav } = this.props;

    return <li>
      <a href={anchor} onClick={this.onClick} className={this.showSelectedClass()}>{name}</a>
      {(this.props.index === this.props.selectedIndex) && subnav && <ChildNavLink links={subnav} />}
    </li>;
  }
}

NavLink.propTypes = {
  anchor: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  subnav: PropTypes.array
};
