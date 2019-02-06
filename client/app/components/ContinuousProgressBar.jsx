import React from 'react';
import PropTypes from 'prop-types';

export default class ContinuousProgressBar extends React.Component {
  render() {
    const percentFilled = this.props.level / this.props.limit * 100;

    return <div className="cf-continuous-progress-bar">
      <div className={this.props.warning ? 'cf-continuous-progress-bar-warning' : ''}
        style={{ width: `${percentFilled > 100 ? 100 : percentFilled}%` }}></div>
    </div>;
  }
}

ContinuousProgressBar.propTypes = {
  limit: PropTypes.number,
  level: PropTypes.number,
  warning: PropTypes.bool
};
