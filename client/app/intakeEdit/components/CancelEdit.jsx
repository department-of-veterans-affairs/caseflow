import React from 'react';
import Button from '../../components/Button';

class CancelEdit extends React.PureComponent {
  closeWindow = () => {
    window.open('', '_self', '');
    window.close();
  }

  render = () =>
    <Button
      id="cancel-intake"
      legacyStyling={false}
      linkStyling
      willNeverBeLoading
      onClick={this.closeWindow}
    >
      Cancel Edit
    </Button>
}

export default CancelEdit;
