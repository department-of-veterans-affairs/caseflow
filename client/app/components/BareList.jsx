import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

export default class BareList extends React.PureComponent {
  render() {
    const {
      ListElementComponent,
      items
    } = this.props;
    const className = classNames('cf-bare-list', this.props.className);

    return <ListElementComponent className={className}>
      {
        items.map((itemFn, index) =>
          <li key={index}>{itemFn()}</li>
        )
      }
    </ListElementComponent>;
  }
}

BareList.propTypes = {
  ListElementComponent: PropTypes.string,
  items: PropTypes.array.isRequired
};

BareList.defaultProps = {
  ListElementComponent: 'ol',
  items: []
};
