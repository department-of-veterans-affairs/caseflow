import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import DocumentListHeader from '../components/reader/DocumentListHeader';
import * as Constants from './constants';
import _ from 'lodash';
import { setDocListScrollPosition, changeSortState,
  clearSearch, setTagFilter, setCategoryFilter } from './actions';
import DocumentsTable from './DocumentsTable';

import { getFilteredDocuments, getAnnotationsPerDocument } from './selectors';
import NoSearchResults from './NoSearchResults';

export class PdfListView extends React.Component {

  render() {
    const showNoSearchResultsMsg = !_.size(this.props.documents) &&
      _.size(this.props.docFilterCriteria.searchQuery);

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <DocumentListHeader documents={this.props.documents} clearSearch={this.props.clearSearch} />
          <div>
            { showNoSearchResultsMsg ?
            <NoSearchResults
              clearSearch={this.props.clearSearch}
              searchQuery={this.props.docFilterCriteria.searchQuery}
              /> :
            <DocumentsTable
              documents={this.props.documents}
              {...this.props}
            />}
          </div>
        </div>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  documents: getFilteredDocuments(state),
  annotationsPerDocument: getAnnotationsPerDocument(state),
  ..._.pick(state, 'tagOptions'),
  ..._.pick(state.ui, 'pdfList', 'docFilterCriteria')
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setDocListScrollPosition,
    setTagFilter,
    setCategoryFilter,
    changeSortState,
    clearSearch
  }, dispatch),
  toggleDropdownFilterVisiblity(filterName) {
    dispatch({
      type: Constants.TOGGLE_FILTER_DROPDOWN,
      payload: {
        filterName
      }
    });
  }
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfListView);

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string,
  pdfList: PropTypes.shape({
    lastReadDocId: PropTypes.number
  })
};
