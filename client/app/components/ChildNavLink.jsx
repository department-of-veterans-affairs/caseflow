import React from 'react';

export default class ChildNavLink extends React.PureComponent {
  render() {
    const { links } = this.props;

    return <ul className="usa-sidenav-sub_list">
      { links.map((link) => <li key={link.name}><a href={link.anchor}>{link.name}</a></li>) }
    </ul>;
  }
}
