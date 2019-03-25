import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../util/ApiUtil';
import _ from 'lodash';

import { loadAppealDocCount, setAppealDocCount, errorFetchingDocumentCount } from './QueueActions';

import { css } from 'glamor';
import { COLORS } from '../constants/AppConstants';

const documentCountStyling = css({
  color: COLORS.GREY
});

class AppealDocumentCount extends React.PureComponent {
  componentDidMount = () => {
    const {
      appeal,
      docCountForAppeal
    } = this.props;

    if (appeal.isPaperCase) {
      return;
    }

    if (docCountForAppeal && docCountForAppeal.docCount) {
      return;
    }

    const requestOptions = {
      withCredentials: true,
      timeout: { response: 5 * 60 * 1000 }
    };

    this.props.loadAppealDocCount(this.props.externalId);

    ApiUtil.get(`/appeals/${this.props.externalId}/document_count`, requestOptions).then((response) => {
      const resp = JSON.parse(response.text);

      this.props.setAppealDocCount(this.props.externalId, resp.document_count);
    }, () => {
      this.props.errorFetchingDocumentCount(this.props.externalId);
    });
  }

  render = () => {
    const {
      docCountForAppeal,
      loadingText
    } = this.props;

    if (docCountForAppeal) {
      if (docCountForAppeal.docCount) {
        return docCountForAppeal.docCount;
      } else if (loadingText && (docCountForAppeal.loading || docCountForAppeal.error)) {
        return docCountForAppeal.error || <span {...documentCountStyling}>Loading number of docs...</span>;
      }
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
    docCountForAppeal: state.queue.docCountForAppeal[externalId] || null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  loadAppealDocCount,
  setAppealDocCount,
  errorFetchingDocumentCount
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AppealDocumentCount);
