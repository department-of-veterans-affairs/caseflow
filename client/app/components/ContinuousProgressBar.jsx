import React from 'react';
import PropTypes from 'prop-types';

export default class ContinuousProgressBar extends React.Component {
  render() {
    return <div className="cf-continuous-progress-bar">
      <div className={this.props.warning ? 'cf-continuous-progress-bar-warning' : ''}
        style={{ width: `${this.props.level / this.props.limit * 100}%` }}></div>
    </div>;
  }
}

ContinuousProgressBar.propTypes = {
  limit: PropTypes.number,
  level: PropTypes.number,
  warning: PropTypes.bool
};

ContinuousProgressBar.defaultProps = {
  limit: 1,
  level: 1
};
