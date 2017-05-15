import { PureComponent } from 'react';
import deepDiff from 'deep-diff';

/* eslint-disable no-console */

export default class PerfDebugPureComponent extends PureComponent {
  componentDidUpdate(prevProps, prevState) {
    const propsDiff = deepDiff(prevProps, this.props);
    const displayName = this.constructor.name || this.displayName || this.name || 'Component';

    console.group(`${displayName} updated`);

    if (propsDiff) {
      console.log('Props', propsDiff);
    }

    const stateDiff = deepDiff(prevState, this.state);

    if (stateDiff) {
      console.log('State', stateDiff);
    }

    if (!(propsDiff || stateDiff)) {
      console.log('Props and state are deeply equal');
    } 

    console.groupEnd();
  }
}
