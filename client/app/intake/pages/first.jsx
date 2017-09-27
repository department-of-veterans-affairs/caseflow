import React from 'react';
import Link from '../../components/Link';

export default class First extends React.PureComponent {

  clickButton() {
    this.props.history.push('/second');
  }

  render() {
    return <div>
      <h1>INTAKE YEAH DUDE</h1>
      <Link to="/second">Second link</Link>
      <button onClick={this.clickButton.bind(this)}>Go</button>
    </div>;
  }
}


