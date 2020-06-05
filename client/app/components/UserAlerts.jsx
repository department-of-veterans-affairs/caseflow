import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _, { uniq } from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';

import { removeAlertsWithTimestamps } from './common/actions';
import Alert from './Alert';

const ALERT_EXPIRATION = 30000;

class UserAlerts extends React.Component {

  componentDidMount () {
    setTimeout(this.removeExpiredAlerts, ALERT_EXPIRATION);
  }

  componentDidUpdate () {
    setTimeout(this.removeExpiredAlerts, ALERT_EXPIRATION);
  }

  removeExpiredAlerts = () => {
    const currentTime = Date.now();
    const { alerts } = this.props;

    const expiredAlertTimestamps = alerts.filter((alert) => (
      (currentTime - alert.timestamp) >= ALERT_EXPIRATION
    )).map((alert) => alert.timestamp);

    if (expiredAlertTimestamps.length > 0) {
      this.props.removeAlertsWithTimestamps(uniq(expiredAlertTimestamps));
    }
  }

  render () {
    const { alerts } = this.props;

    if (_.isUndefined(alerts) || _.isNull(alerts) || _.isEmpty(alerts)) {
      return null;
    }

    return (
      <div className="cf-alerts-container cf-margin-bottom-2rem">
        {alerts.map(({ type, message, title, timestamp }, index) => (
          <Alert type={type}
            message={
              message ? <div
                className="cf-margin-top-1rem cf-margin-bottom-1rem"
                dangerouslySetInnerHTML={{ __html: message }} /> : null
            }
            title={title}
            key={`alert-${timestamp}-${index}`} />
        ))}
      </div>
    );
  }
}

UserAlerts.propTypes = {
  alerts: PropTypes.arrayOf(PropTypes.shape({
    type: PropTypes.oneOf(['success', 'info', 'warning', 'error']),
    message: PropTypes.string,
    title: PropTypes.string,
    timestamp: PropTypes.integer
  })),
  removeAlertsWithTimestamps: PropTypes.func
};

UserAlerts.defaultProps = {
  alerts: []
};

const mapStateToProps = (state) => ({
  alerts: state.components.alerts
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  removeAlertsWithTimestamps
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(UserAlerts);
