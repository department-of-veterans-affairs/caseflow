import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Alert from './Alert';
import { uniq } from 'lodash';
import { removeAlertsWithExpiration } from './common/actions';

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
      (currentTime - alert.timestamp) >= ALERT_EXPIRATION && alert.autoClear
    )).map((alert) => alert.timestamp);

    if (expiredAlertTimestamps.length > 0) {
      this.props.removeAlertsWithExpiration(uniq(expiredAlertTimestamps));
    }
  }

  render () {
    const { alerts } = this.props;

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
    timestamp: PropTypes.integer,
    autoClear: PropTypes.bool
  })),
  removeAlertsWithExpiration: PropTypes.func
};

UserAlerts.defaultProps = {
  alerts: []
};

const mapStateToProps = (state) => ({
  alerts: state.components.alerts
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  removeAlertsWithExpiration
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(UserAlerts);
