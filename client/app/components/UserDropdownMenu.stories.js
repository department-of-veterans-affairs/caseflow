import React from 'react';

export default {
  title: 'Commons/Components/Layout/UserDropdownMenu'
};

const Template = () => (
  <div className="cf-nav cf-dropdown">
    <a href="#menu" className="cf-dropdown-trigger" id="menu-trigger">
      BVACHANE at 101 - Candida H Hane
    </a>

    <ul id="menu" className="cf-dropdown-menu" aria-labelledby="menu-trigger">
      <li>
        <a>Help</a>
      </li>
      <li>
        <a>Send Feedback</a>
      </li>
      <li>
        <a>Switch User</a>
      </li>

      <li>
        <div className="dropdown-border"></div>
        <a>Sign out</a>
      </li>
    </ul>
  </div>
);

export const UserDropdownMenu = Template.bind({});
