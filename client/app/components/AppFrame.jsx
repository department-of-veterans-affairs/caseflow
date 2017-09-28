import React from 'react';

export default class AppFrame extends React.PureComponent {
  render = () =>
    <main className="cf-app-width">
      {this.props.children}
    </main>
}
