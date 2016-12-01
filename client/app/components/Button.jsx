import React, { PropTypes } from 'react';
export default class Button extends React.Component {
  render() {
    let {
      name,
      disabled,
      loading,
      onClick
    } = this.props;

    return <div className={`cf-app-segment${loading ? " cf-is-loading" : ""}`}>
      {loading &&
        <div className="cf-loading-indicator cf-push-right">
          Loading
          <img src="loading-back.svg"/>
          <img src="loading-front.svg"/>

        </div>
      }
      {!loading &&
      	<button type="submit" className="cf-push-right" disabled={disabled} onClick={onClick}>
              {name}
        </button>
      }
    </div>;
  }
}

Button.propTypes = {
  name: PropTypes.string.isRequired,
  disabled: PropTypes.bool,
  loading: PropTypes.bool,
  onClick: PropTypes.func
};
