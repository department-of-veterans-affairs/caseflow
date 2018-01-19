import React from 'react';
import Link from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/Link';

class BoldOnCondition extends React.PureComponent {
  render = () => this.props.condition ? <strong>{this.props.children}</strong> : this.props.children
}

export default class ViewableItemLink extends React.PureComponent {
  // Annoyingly, if we make this call in this event loop iteration, it won't follow the link. 
  // Instead, we use setTimeout to force it to run at a later point.
  onClick = () => setTimeout(this.props.onOpen);

  render = () => <BoldOnCondition condition={this.props.boldCondition}>
    <Link
      {...this.props.linkProps}
      onMouseUp={this.onClick}>
      {this.props.children}
    </Link>
  </BoldOnCondition>
}
