import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveDocs } from '../reader/Documents/DocumentsActions';
import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import * as Constants from './constants';

class QueueLoadingScreen extends React.Component {
  createLoadPromise = () => {
    // if (this.props.loadedAppealId && this.props.loadedAppealId === this.props.vacolsId) {
    //   return Promise.resolve();
    // }

    // return ApiUtil.get(`/queue/${this.props.userId}`, {}).
    return ApiUtil.get(`/queue/${1}`, {}).
      then((response) => {
        const returnedObject = JSON.parse(response.text);
        const documents = returnedObject.appealDocuments;

        this.props.onReceiveDocs(documents, this.props.vacolsId);
      });
  }

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load this case.<br />
      Please <a href="javascript:void(0)" onClick={() => location.reload()}>refresh the page</a> and try again.
    </div>

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingScreenProps={{
        spinnerColor: Constants.QUEUE_COLOR,
        message: 'Loading claims folder in Reader...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load documents'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;

    return <div className="usa-grid">
      <div className="cf-app">
        {loadingDataDisplay}
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  // loadedAppealId: state.pdfViewer.loadedAppealId
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    onReceiveDocs
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(QueueLoadingScreen);
