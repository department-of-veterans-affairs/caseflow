import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import { css } from 'glamor';

export default class BareList extends React.PureComponent {
  bottomMargin = () => css({
    marginBottom: this.props.compact ? '5px' : ''
  });

  render() {
    const {
      ListElementComponent,
      items,
      listStyle
    } = this.props;
    const className = classNames('cf-bare-list', this.props.className);

    return <ListElementComponent {...listStyle} className={className}>
      {
        items.map((itemFn, index) =>
          <li {...this.bottomMargin()} key={index}>{itemFn()}</li>
        )
      }
    </ListElementComponent>;
  }
}

BareList.propTypes = {
  ListElementComponent: PropTypes.string,
  items: PropTypes.array.isRequired,
  compact: PropTypes.bool,
  listStyle: PropTypes.object
};

BareList.defaultProps = {
  ListElementComponent: 'ol',
  items: [],
  compact: false,
  listStyle: {}
};
