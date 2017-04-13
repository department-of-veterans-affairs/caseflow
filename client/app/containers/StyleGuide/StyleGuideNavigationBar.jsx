import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideNavigationBar extends React.Component {
  render(){
    return <div>
      <StyleGuideComponentTitle
        title="Navigation Bar"
        id="navigation_bar"
        link="StyleGuideNavigationBar.jsx"
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
      The navigation bar is a total of 90px tall with a 1px border-botom colored grey-lighter.
    </p>
      <nav className="cf-nav">
        <a href="#" id="cf-logo-link">
          <h1 className="cf-logo"><span className="cf-logo-image cf-logo-image-default"></span>Caseflow</h1>
        </a>
        <h2 id="page-title" className="cf-application-title">App Name</h2>
          <div className="cf-dropdown cf-nav-dropdown">
            <a href="#menu" className="cf-dropdown-trigger" id="menu-trigger">
              Fake User
            </a>
            <ul id="menu" className="cf-dropdown-menu" aria-labelledby="menu-trigger">
              <li><a href="#">Help</a></li>
              <li><a href="#">Send Feedback</a></li>
              <li><a href="#">What's New?</a></li>
              <li><a href="#">Switch User</a></li>
              <li><a href="#">Change Functions</a></li>
              <li>
                <div class="dropdown-border"></div>
                <a href="#">Sign out</a>
              </li>
            </ul>
          </div>
    </nav>
  </div>
  }
}
