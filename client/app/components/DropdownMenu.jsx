import React, { PropTypes } from 'react';

export default class DropdownMenu extends React.Component {
  render() {
    let {
      label,
      options
    } = this.props;

    let dropdownMenuList = () => {
      return <ul id="dropdown-menu" className="cf-dropdown-menu active"
        aria-labelledby="menu-trigger">
        {options.map((option, index) =>
          <li key={index}>
            {options.length - 1 === index && <div className="dropdown-border"></div>}
            <a href={option.link}>{option.title}</a>
          </li>)}
      </ul>;
    };

    return <div className="cf-dropdown">
      <a href="#dropdown-menu"
        className="cf-dropdown-trigger">
        {label}
      </a>
      {this.state.menu && dropdownMenuList() }
    </div>;
  }
}

DropdownMenu.propTypes = {
  options: PropTypes.arrayOf(PropTypes.shape({
    title: PropTypes.string.isRequired,
    link: PropTypes.string.isRequired
  })),
  label: PropTypes.string.isRequired
};
