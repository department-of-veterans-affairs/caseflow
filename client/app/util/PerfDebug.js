import { PureComponent, Component } from 'react';
import deepDiff from 'deep-diff';

/* eslint-disable no-console */

// eslint-disable-next-line func-style
function componentDidUpdate(prevProps, prevState) {
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

export class PerfDebugPureComponent extends PureComponent {
  componentDidUpdate = componentDidUpdate
}

export class PerfDebugComponent extends Component {
  componentDidUpdate = componentDidUpdate
}
