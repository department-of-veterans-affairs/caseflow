import React from 'react';
import Alert from '../components/Alert';
import { css } from 'glamor';
import { storeMetrics } from '../util/Metrics';
import uuid from 'uuid';

// variables being defined are in mbps
const bandwidthThreshold = 1.5;

const alertStyling = css({
  marginBottom: '20px'
});

class BandwidthAlert extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      displayBandwidthAlert: false
    };
  }

  componentDidMount() {
    if ('connection' in navigator) {
      this.updateConnectionInfo();
    }
  }

  updateConnectionInfo = () => {
    const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;

    if (connection.downlink && connection.downlink < bandwidthThreshold) {
      const logId = uuid.v4();

      storeMetrics(logId, { bandwidth: this.state.downlink }, {
        message: 'Bandwidth Alert Displayed',
        type: 'metric',
        product: 'reader'
      },
      null);
      this.setState({ displayBandwidthAlert: true });
    }
  };

  render() {

    if (this.state.displayBandwidthAlert) {
      return (
        <div {...alertStyling}>
          <Alert title="Slow bandwidth" type="warning">
            You may experience slower downloading times for certain files based on your
            bandwidth speed and document size.
            <br />
          </Alert>
        </div>
      );
    }

    return null;
  }
}

export default BandwidthAlert;
