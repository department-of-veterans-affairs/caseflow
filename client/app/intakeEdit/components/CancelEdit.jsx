import React from 'react';
import Button from '../../components/Button';

class CancelEdit extends React.PureComponent {
  render = () => {
    return <Button
      id="cancel-edit"
      legacyStyling={false}
      linkStyling
      willNeverBeLoading
      onClick={() => {this.props.history.push('/cancel')}}
    >
      Cancel edit
    </Button>
  }
}

export default CancelEdit;
