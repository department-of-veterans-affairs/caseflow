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
    };
  }
  // TODO This function for testing purposes only
  onClickChangeText = () => {
    this.setState({
      ...this.state,
      modal: true
    });
  };



  timeOut = (mills) => {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        resolve(true);
      }, mills);
    })
  }

  render = () => {
    const {
      ...btnProps
    } = this.props;

    return (
      <div style={{height: '75vh'}}>
        {
          this.state.showBanner && 
          <div style={{padding: '10px'}}>
            <Alert message="download success" type="success" />
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
            confirmButton={<Button onClick={async () => {
              this.setState({
                ...this.state,
                modal: false,
                isLoading: true
              });

              // window.open('./test.csv', '_parent', 'download');
              var fileData = "VET_LAST_NAME,VET_FIRST_NAME,VET_MIDDLE_NAME,VET_DATE_OF_BIRTH,VET_SSN,VET_PARTICIPANT_ID,VET_FILE_NUMBER,APPELLANT_LAST_NAME,APPELLANT_FIRST_NAME,APPELLANT_MIDDLE_NAME,APPELLANT_DATE_OF_BIRTH,APPELLANT_SSN,APPELLANT_GENDER,APPELLANT_ADDRESS,APPELLANT_PHONE,APPELLANT_EMAIL,APPELLANT_EDI_PI,APPELLANT_CORP_PID,APPELLANT_VACOLS_INTERNAL_ID,RELATIONSHIP_TO_VETERAN";
              var downloadLink = document.createElement("a");
              var blob = new Blob(["\ufeff", fileData]);
              var url = URL.createObjectURL(blob);
              downloadLink.href = url;
              downloadLink.download = "data.csv";

              document.body.appendChild(downloadLink);
              downloadLink.click();
              document.body.removeChild(downloadLink);

              // wait until download complete
              await this.timeOut(5000);
              // stop loading 
              this.setState({
                ...this.state,
                isLoading: false,
                showBanner: true
              });
            }}>Okay</Button>}
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
