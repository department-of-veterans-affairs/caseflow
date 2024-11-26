import React from 'react';
import Alert from '../components/Alert';
import { css } from 'glamor';

const alertStyling = css({
  marginBottom: '20px'
});

class BandwidthAlert extends React.Component {
  render() {
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

export default BandwidthAlert;
