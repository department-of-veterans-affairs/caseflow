import React from 'react';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import Alert from '../../components/Alert';
import LoadingContainer from '../../components/LoadingContainer';
import { LOGO_COLORS } from 'app/constants/AppConstants';

class GenerateButton extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      modal: false,
      isLoading: false,
      showBanner: false,
      showErrorBanner: false
    };
  }
  // TODO This function for testing purposes only
  onClickChangeText = () => {
    this.setState({
      ...this.state,
      modal: true
    });
  };

  onClickConfirmation = () => {
    this.setState({
      ...this.state,
      modal: false,
      isLoading: true
    });

    var request = new XMLHttpRequest();
    request.responseType = 'blob';
    request.open('get', '/admin.csv', true);
    request.send();

    request.onreadystatechange =  () => {
      if (request.readyState === 4 && request.status === 200) {
        const downloadLink = document.createElement("a");
        const blob = new Blob(["\ufeff", request.response]);
        const url = URL.createObjectURL(blob);
        downloadLink.href = url;
        downloadLink.download = "data.csv";

        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);

        // stop loading
        this.setState({
          ...this.state,
          isLoading: false,
          showBanner: true
        });
      } else if(request.readyState === 4 && (request.status < 200 || request.status >= 300)){
         // stop loading
         this.setState({
          ...this.state,
          isLoading: false,
          showErrorBanner: true
        });
      }
    };
  }

  render = () => {
    const {
      ...btnProps
    } = this.props;

    return (
      <div style={{ height: '75vh' }}>
        {
          this.state.showBanner &&
          <div style={{ padding: '10px' }}>
            <Alert message="download success" type="success" />
          </div>
        }
        {
          this.state.showErrorBanner &&
          <div style={{ padding: '10px' }}>
            <Alert message="download failed" type="error" />
          </div>
        }
        {
          !this.state.isLoading &&
          <Button
            id="generate-extract"
            onClick={() => this.onClickChangeText()}
            {...btnProps}
          >
            Generate
          </Button>
        }
        {
          this.state.modal &&

          <Modal title="The file contains PII information, click OK to proceed"
            confirmButton={<Button onClick={ () => {this.onClickConfirmation()}}>Okay</Button>}
            closeHandler={() => { this.setState({ ...this.state, modal: false }); }}
          >
            Whenever you are click on Okay button then file will start downloading.
          </Modal>
        }
        {
          this.state.isLoading &&

          <LoadingContainer color={LOGO_COLORS.QUEUE.ACCENT}>
            <div className="loading-div">
              Action is Running...
            </div>
          </LoadingContainer>
        }
      </div>
    );
  };
}
GenerateButton.propTypes = {
};

export default GenerateButton;
