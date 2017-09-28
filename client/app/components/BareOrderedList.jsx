import React from 'react';
import classNames from 'classnames';

export default class BareOrderedList extends React.PureComponent {
  render() {
    const className = classNames('cf-bare-list', this.props.className);

    return <ol className={className}>
      {
        this.props.items.map((itemFn, index) =>
          <li key={index}>{itemFn()}</li>
        )
      }
    </ol>;
  }
}
