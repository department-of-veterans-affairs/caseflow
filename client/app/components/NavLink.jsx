import React from 'react';
import PropTypes from 'prop-types';

// To be used with the "StickyNav" component
// This generates the list of links for a side navigation list

const NavLink = (props) => {
  const { anchor, name } = props;

  return <li><a href={anchor}>{name}</a></li>;
};

NavLink.propTypes = {
  anchor: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired
};

export default NavLink;
