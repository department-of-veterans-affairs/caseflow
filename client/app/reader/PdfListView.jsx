import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import DocumentListHeader from '../components/reader/DocumentListHeader';
import ClaimsFolderDetails from './ClaimsFolderDetails';
import { fetchAppealDetails, onReceiveAppealDetails } from './actions';
import { getAppealIfItDoesNotExist } from '../reader/utils';

import _ from 'lodash';
import DocumentsTable from './DocumentsTable';

import { getFilteredDocuments } from './selectors';
import NoSearchResults from './NoSearchResults';

export class PdfListView extends React.Component {
  componentDidMount() {
    getAppealIfItDoesNotExist(this);
  }

  render() {
    const noDocuments = !_.size(this.props.documents) && _.size(this.props.docFilterCriteria.searchQuery) > 0;

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <ClaimsFolderDetails appeal={this.props.appeal} documents={this.props.documents}/>
          <DocumentListHeader
            documents={this.props.documents}
            noDocuments={noDocuments}
          />
          { noDocuments ?
          <NoSearchResults /> :
          <DocumentsTable
            documents={this.props.documents}
            documentPathBase={this.props.documentPathBase}
            onJumpToComment={this.props.onJumpToComment}
            sortBy={this.props.sortBy}
            docFilterCriteria={this.props.docFilterCriteria}
            showPdf={this.props.showPdf}
          />}
        </div>
      </div>
    </div>;
  }
}

const mapStateToProps = (state, props) => {
  return { documents: getFilteredDocuments(state),
    ..._.pick(state.ui, 'docFilterCriteria'),
    appeal: _.find(state.assignments, { vacols_id: props.match.params.vacolsId }) ||
      state.loadedAppeal,
    caseSelectedAppeal: state.ui.caseSelect.selectedAppeal
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    fetchAppealDetails,
    onReceiveAppealDetails
  }, dispatch)
);

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfListView);

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string
};
