import React, { PropTypes } from 'react';
import { loadingSymbolHtml } from './RenderFunctions.jsx';

export default class Button extends React.Component {
  render() {
    let {
      name,
      disabled,
      loading,
      onClick
    } = this.props;

    return <div className={'cf-app-segment cf-push-right'}>
    {loading && loadingSymbolHtml()}
    {!loading &&
      <button
        type="submit"
        className="cf-submit"
        disabled={disabled}
        onClick={onClick}>
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
