import React from 'react';

export default class AppFrame extends React.PureComponent {
  render() {
    return <main className="cf-app-width cf-app-segment cf-app-segment--alt">
      {this.props.children}
    </main>;
  }
}
