import React from 'react';
import Alert from '../components/Alert';
import { css } from 'glamor';
import PropTypes from 'prop-types';

const alertStyling = css({
  marginBottom: '20px'
});

class BandwidthAlert extends React.Component {
  render() {
    if (this.props.displayBanner) {
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
  }
}

BandwidthAlert.propTypes = {
  displayBanner: PropTypes.bool.isRequired
};

export default BandwidthAlert;
