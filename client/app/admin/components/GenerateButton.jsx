import React from 'react';
import Button from '../../components/Button';

class GenerateButton extends React.PureComponent {
  // TODO This function for testing purposes only
  onClickChangeText = () => {
    let x = document.getElementById('generate-extract');

    if (x.innerHTML === 'Generate') {
      x.innerHTML = 'Button Clicked.';
    } else {
      x.innerHTML = 'Generate';
    }
  };

  render = () => {
    const {
      ...btnProps
    } = this.props;

    return (
      <Button
        id="generate-extract"
        linkStyling
        willNeverBeLoading
        // TODO this onClick function will need to be changed
        onClick={() => this.onClickChangeText()}
        {...btnProps}
      >
        Generate
      </Button>
    );
  };
}
GenerateButton.propTypes = {
};

export default GenerateButton;
