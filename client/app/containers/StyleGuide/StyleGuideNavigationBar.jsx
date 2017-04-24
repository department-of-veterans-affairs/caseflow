import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';
import DropdownMenu from '../../components/DropdownMenu';

export default class StyleGuideNavigationBar extends React.Component {
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

  render() {
    let {
      name
    } = this.props;

    name = 'App Bar';

    return <div className="sg-nav-bar">
      <StyleGuideComponentTitle
        title="Navigation Bar"
        id="navigation_bar"
        link="StyleGuideNavigationBar.jsx"
        subsection={true}
      />
    <p>
      The Navigation Bar is a simple white bar that sits on top of every application.
      Our navigation bar is non-sticky and scrolls out of view as the user scrolls
      down the page. It includes branding for the specific application on the left;
      a Caseflow logo and application name (see Application Branding for more details).
    </p>
    <p>
      The Navigation Bar also includes the user menu on the right.
      This menu indicates which user is signed in and contains links to submit feedback,
      view the application’s help page, see newly launched features, and log out.
    </p>
    <p>
      The navigation bar is a total of 90px tall with a 1px border-bottom colored
      grey-lighter.
    </p>
      <div>
        <nav className="cf-nav">
          <a href="#" id="cf-logo-link">
            <h1 className="cf-logo"><span className="cf-logo-image cf-logo-image-default">
            </span>Caseflow</h1>
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
  </div>;
  }
}
