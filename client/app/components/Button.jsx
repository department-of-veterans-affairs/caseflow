import React, { PropTypes } from 'react';
import {loading_symbol_html} from './RenderFunctions.jsx';

export default class Button extends React.Component {
  render() {
    let {
      name,
      disabled,
      loading,
      onClick
    } = this.props;

    return <div className={'cf-app-segment'}>
    {loading && loading_symbol_html()}
    {!loading &&
      <button type="submit" className="cf-push-right cf-submit" disabled={disabled} onClick={onClick}>
            {name}
      </button>
    }
    </div>;
  }
}

Button.propTypes = {
  disabled: PropTypes.bool,
  loading: PropTypes.bool,
  name: PropTypes.string.isRequired,
  onClick: PropTypes.func
};
