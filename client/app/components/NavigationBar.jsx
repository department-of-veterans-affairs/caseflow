import React from 'react';
import DropdownMenu from './DropdownMenu';

// This component must be used with the "DropdownMenu" component.

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

  options = () => {
    return [
      {
        title: 'Help',
        link: '#navigation_bar'
      },
      {
        title: 'Send feedback',
        link: '#navigation_bar'
      },
      {
        title: 'Sign out',
        link: '#navigation_bar'
      }
    ];
  }

  render(){
    let {
      name
    } = this.props;

    return <div>
      <nav className="cf-nav">
        <a href="#" id="cf-logo-link">
          <h1 className="cf-logo"><span className="cf-logo-image cf-logo-image-default"></span>Caseflow</h1>
        </a>
        <h2 id="page-title" className="cf-application-title">&nbsp; &nbsp; {name}</h2>
        <div className="cf-dropdown cf-nav-dropdown">
          <DropdownMenu
            options={this.options()}
            onClick={this.handleMenuClick}
            onBlur={this.handleMenuClick}
            label="Abraham Lincoln"
            menu={this.state.menu}
            />
        </div>
    </nav>
    <br />
  </div>
  }
}
