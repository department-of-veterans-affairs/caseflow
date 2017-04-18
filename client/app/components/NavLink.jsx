import React from 'react';
// To be used with the "StickyNav" component

export default class NavLink extends React.Component {
  render(){
    let {
      anchor,
      name,
      subsection
    } = this.props;

    if (subsection === true) {
      return <ul className="usa-sidenav-sub_list">
        { React.cloneElement(<li><a href={anchor}>{name}</a></li>) }
      </ul>
    }
    return <li><a href={anchor}>{name}</a></li>
  }
}
