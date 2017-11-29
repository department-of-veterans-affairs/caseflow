import React from 'react';
import classnames from 'classnames';
import { showSelectedClass } from '../containers/StyleGuide/NavigationUtils';

export default class ChildNavLink extends React.PureComponent {
  onClick = () => {
    this.props.setSelectedLink(this.props.index);
  }

  render() {
    const { name, anchor, index, selectedIndex } = this.props;

    return <li><a href={anchor} onClick={this.onClick} className={showSelectedClass(index, selectedIndex)}>{name}</a></li>;
  }
}
