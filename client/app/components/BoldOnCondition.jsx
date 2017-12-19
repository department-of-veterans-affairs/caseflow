import React from 'react';

export default class BoldOnCondition extends React.PureComponent {
  render = () => this.props.condition ? <strong>{this.props.children}</strong> : this.props.children
}
