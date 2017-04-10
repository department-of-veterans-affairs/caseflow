import React, { PropTypes } from 'react';

export default class DropDown extends React.Component {
  constructor(props){
    super(props);
    this.state = {
      menu: false
    }
  }

  handleMenuClick = (e) => {
    e.stopPropagation();
    this.setState({menu: !this.state.menu});
  };

  showDropdownBorder = () => {
    return <div class="dropdown-border"></div>;
  }

  render() {
    let {
      label,
      link,
      options
    } = this.props;

    return <div className="cf-dropdown">
      <a href="#menu" className="cf-dropdown-trigger" onClick={this.handleMenuClick}>
        {label}
      </a>
      {this.state.menu && <ul id="menu" className="cf-dropdown-menu active" aria-labelledby="menu-trigger">
        {options.map((option, index) =>
          <li key={index}>
            <a href={option.link}>{option.title}</a>
          </li>)}
      </ul>
    }
    </div>
  }
};
