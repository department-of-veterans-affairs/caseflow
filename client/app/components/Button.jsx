import React, { PropTypes } from 'react';
import { loadingSymbolHtml } from './RenderFunctions.jsx';

export default class Button extends React.Component {
  render() {
    let {
      classNames,
      name,
      disabled,
      loading,
      onClick
    } = this.props;

    return <span>
    {loading && loadingSymbolHtml()}
    {!loading &&
      <button
        type="submit"
        className={classNames ? classNames.join(' ') : "cf-submit"}
        disabled={disabled}
        onClick={onClick}>
          {name}
      </button>
    }
    </span>;
  }
}

Button.propTypes = {
  disabled: PropTypes.bool,
  loading: PropTypes.bool,
  name: PropTypes.string.isRequired,
  onClick: PropTypes.func
};
