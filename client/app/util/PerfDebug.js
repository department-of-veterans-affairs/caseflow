import { PureComponent, Component } from 'react';
import deepDiff from 'deep-diff';
import _ from 'lodash';

/* eslint-disable no-console */

// eslint-disable-next-line func-style,max-statements
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
    const logEqualityType = (name, lhs, rhs) => {
      const equalityType = lhs === rhs ? 'shallowly' : 'deeply';

      console.log(`Previous and current ${name} is ${equalityType} equal`);
    };

    logEqualityType('props', prevProps, this.props);
    logEqualityType('state', prevState, this.state);
  }

  console.groupEnd();
}

export class PerfDebugPureComponent extends PureComponent {
  componentDidUpdate = componentDidUpdate
}

export class PerfDebugComponent extends Component {
  componentDidUpdate = componentDidUpdate
}

const getTimeLabel = (countMs) => `${countMs.toFixed(2)}ms`;

export const timeFunction = (fn, getLabel) => (...args) => {
  const startMs = window.performance.now();
  const returnValue = fn(...args);
  const endMs = window.performance.now();

  if (startMs !== 'RUNNING_IN_NODE') {
    // eslint-disable-next-line no-console

    const timeLabel = getTimeLabel(endMs - startMs);
    const label = _.isFunction(getLabel) ? getLabel(timeLabel, ...args) : `${getLabel} took ${timeLabel}`;

    console.log(label);
  }

  return returnValue;
};

export const timeFunctionPromise = (fn, onTimeElapsed, label = '') => (...args) => {
  const startMs = window.performance.now();
  const returnPromise = fn(...args);

  if (startMs !== 'RUNNING_IN_NODE') {
    returnPromise.then(() => {
      const endMs = window.performance.now();

      const timeElapsedMs = endMs - startMs;

      onTimeElapsed(timeElapsedMs, ...args);

      if (label) {
        console.log(`${label} took ${getTimeLabel(timeElapsedMs)}.`);
      }
    });
  }

  return returnPromise;
};
