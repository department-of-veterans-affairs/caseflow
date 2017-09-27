import React from 'react';

export default class AppFrame extends React.PureComponent {
  render() {
    return <main className="cf-app-width">
      {this.props.children}
    </main>;
  }
}
