import React from 'react';
import PropTypes from 'prop-types';

// To be used with the "StickyNav" component
// This generates the list of links for a side navigation list

const NavLink = (props) => {
  const { anchor, name } = props;

  return <a href={anchor}>{name}</a>;
};

NavLink.propTypes = {
  anchor: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired
};

export default NavLink;
