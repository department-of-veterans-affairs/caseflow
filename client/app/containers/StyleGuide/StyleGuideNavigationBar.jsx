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
