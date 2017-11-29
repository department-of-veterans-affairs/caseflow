import React from 'react';
import PropTypes from 'prop-types';
import ChildNavLink from './ChildNavLink';
import classnames from 'classnames';
import { showSelectedClass } from '../containers/StyleGuide/NavigationUtils';

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
    this.props.setSelectedLink(this.props.index);
  }

  setSelectedLink = (index) => {
    this.setState({
      selected: index
    });
  }

  render() {
    const { anchor, name, subnav, index, selectedIndex } = this.props;

    return <li>
      <a href={anchor} onClick={this.onClick} className={showSelectedClass(index, selectedIndex)}>{name}</a>
      {(this.props.index === this.props.selectedIndex) && subnav && <ul className="usa-sidenav-sub_list">
        {
          subnav.map((link, i) => {
            return <ChildNavLink key={i} index={i} name={link.name} anchor={link.anchor}
              setSelectedLink={this.setSelectedLink} selectedIndex={this.state.selected} />;
          })
        }
      </ul>}
    </li>;
  }
}

NavLink.propTypes = {
  anchor: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  subnav: PropTypes.array
};
