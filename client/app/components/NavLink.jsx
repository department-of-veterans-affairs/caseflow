import React from 'react';
// import PropTypes from 'prop-types'; TODO(marian): define props for ChildNavLink

// To be used with the "StickyNav" component
// This generates the list of links for a side navigation list

export const NavLink = (props) => {
  return <a href={props.anchor}>{props.name}</a>;
};

export const ChildNavLink = (props) => {
  return <ul className="usa-sidenav-sub_list">
    { props.links.map((link, i) => {
      return <li key={i}><a href={link.anchor}>{link.name}</a></li>;
    }
    )
    }
  </ul>;
};
