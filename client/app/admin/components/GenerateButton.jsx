import React from 'react';
import Button from '../../components/Button';
import Modal from '../../components/Modal';

class GenerateButton extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      modal: false
    };
  }
  // TODO This function for testing purposes only
  onClickChangeText = () => {
    this.setState({ modal: true });
  };

  render = () => {
    const {
      ...btnProps
    } = this.props;

    return (
      <>
        <Button
          id="generate-extract"
          onClick={() => this.onClickChangeText()}
          {...btnProps}
        >
          Generate
        </Button>
        {this.state.modal && <Modal title="The file contains PII information, click OK to proceed"
        confirmButton={ <Button onClick={() => {this.setState({ modal: false });}}>Okay</Button>}
        closeHandler={() => {this.setState({ modal: false });}}
        >
        Whenever you are click on Okay button then file will start downloading.
        </Modal>}
      </>
    );
  };
}
GenerateButton.propTypes = {
};

export default GenerateButton;
