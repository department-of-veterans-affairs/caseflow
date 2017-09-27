import React from 'react';
import Link from '../../components/Link';
import { browserHistory } from 'react-router'

export default class First extends React.PureComponent {

  clickButton() {
    browserHistory.push('/intake/second');
  }

  render() {
    return <div>
      <h1>INTAKE YEAH DUDE</h1>
      <Link to="/second">Second link</Link>
      <button click={this.clickButton}>Go</button>
    </div>;
  }
}


