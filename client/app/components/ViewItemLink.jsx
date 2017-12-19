import React from 'react';
import Link from './Link';

class BoldOnCondition extends React.PureComponent {
  render = () => this.props.condition ? <strong>{this.props.children}</strong> : this.props.children
}

export default class ViewItemLink extends React.PureComponent {
  // Annoyingly, if we make this call in this event loop iteration, it won't follow the link. 
  // Instead, we use setTimeout to force it to run at a later point.
  onClick = () => setTimeout(this.props.onOpen);

  render = () => <BoldOnCondition condition={this.props.boldCondition}>
    <Link
      {...this.props.linkProps}
      onMouseUp={this.onClick}
      onClick={this.onClick}>
      {this.props.children}
    </Link>
  </BoldOnCondition>
}
