import React from 'react';
import Alert from '../../components/Alert';

export class FlashAlerts extends React.PureComponent {
  render() {

    let alerts = this.props.flash.map((flash, idx) => {
      let flashMsg;

      if (flash[0] === 'success') {
        flashMsg = <Alert key={idx} title="Success!" type="success" >{flash[1]}</Alert>;
      } else if (flash[0] === 'notice') {
        flashMsg = <Alert key={idx} title="Note" type="info" >{flash[1]}</Alert>;
      } else if (flash[0] === 'error') {
        flashMsg = <Alert key={idx} title="Error" type="error" >{flash[1]}</Alert>;
      } else if (flash[0] === 'removed') {
        flashMsg = <Alert key={idx} title="Review Removed" type="success">{flash[1]}</Alert>;
      }

      return flashMsg;
    });

    return <div className="cf-flash-messages">{alerts}</div>;
  }
}
