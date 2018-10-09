import React from 'react';
import Button from '../../components/Button';

class CancelEditButton extends React.PureComponent {
  render = () => {
    return <Button
      id="cancel-edit"
      linkStyling
      willNeverBeLoading
      onClick={
        () => {
          this.props.history.push('/cancel');
        }
      }
    >
      Cancel edit
    </Button>;
  }
}

export default CancelEditButton;
