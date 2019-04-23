import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import { loadAppealDocCount, setAppealDocCount, errorFetchingDocumentCount } from './QueueActions';

import { css } from 'glamor';
import { COLORS } from '../constants/AppConstants';

const documentCountStyling = css({
  color: COLORS.GREY
});

class AppealDocumentCount extends React.PureComponent {
  render = () => {
    const {
      loadingText,
      externalId
    } = this.props;
    // see: https://bit.ly/2UwdQdS
    const docCountsInLocalStorage = JSON.parse(localStorage.getItem('docCountsByAppealId'));
    let docCountsByAppealId;

    if (_.isEmpty(this.props.docCountsByAppealId) && docCountsInLocalStorage) {
      docCountsByAppealId = docCountsInLocalStorage;
    } else {
      docCountsByAppealId = this.props.docCountsByAppealId;
    }

    const isLoading = loadingText && (docCountsByAppealId.loading);
    const errorLoadingDocumentCount = _.get(docCountsByAppealId[externalId], 'error');
    const documentCount = _.get(docCountsByAppealId[externalId], 'count', null);

    if (!_.isEmpty(docCountsByAppealId)) {
      localStorage.setItem('docCountsByAppealId', JSON.stringify(docCountsByAppealId));
      if (isLoading) {
        return <span {...documentCountStyling}>Loading number of docs...</span>;
      }

      return errorLoadingDocumentCount || documentCount;
    }

    return null;
  }
}

AppealDocumentCount.propTypes = {
  appeal: PropTypes.object.isRequired,
  loadingText: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => {
  const externalId = ownProps.appeal.externalId;

  return {
    externalId,
    docCountsByAppealId: state.queue.docCountsByAppealId
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  loadAppealDocCount,
  setAppealDocCount,
  errorFetchingDocumentCount
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AppealDocumentCount);
