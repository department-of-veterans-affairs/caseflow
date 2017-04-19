import React, { PropTypes } from 'react';
// To be used with the "StickyNav" component
// This generates the list of links for a side navigation list

export default class NavLink extends React.Component {
  render() {
    let {
      links
    } = this.props;

    return <div className="cf-push-left cf-sg-nav">
      <ul className="usa-sidenav-list">
        {links.map((link, index) =>
          <li key={index}>
            <a href={link.anchor}>{link.name}</a>
          </li>)}
      </ul>
    </div>;
  }
}


NavLink.propTypes = {
  links: PropTypes.arrayOf(PropTypes.shape({
    anchor: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired
  }))
};
