import React from 'react';
import { LoadingIcon } from './icons/LoadingIcon';
import PropTypes from 'prop-types';

export default class SmallLoader extends React.Component {

  render() {
    const {
      message,
      spinnerColor,
      componentProps,
      component: Component
    } = this.props;

    return <Component
      id="small-loader"
      className="cf-small-loader"
      {...componentProps}>
      <LoadingIcon
        text={message}
        size={19}
        color={spinnerColor}
      />
    </Component>;
  }
}

SmallLoader.defaultProps = {
  component: 'div',
  componentProps: {}
};

SmallLoader.propTypes = {
  message: PropTypes.string.isRequired,
  spinnerColor: PropTypes.string.isRequired,
  component: PropTypes.oneOfType([
    PropTypes.func,
    PropTypes.string
  ]).isRequired,
  componentProps: PropTypes.object
};
