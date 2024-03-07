import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../util/ApiUtil';
import { getMinutesToMilliseconds } from '../util/DateUtil';
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

    if (docCountForAppeal && (docCountForAppeal.docCountText || docCountForAppeal.docCountText === 0)) {
      return;
    }

    const requestOptions = {
      withCredentials: true,
      timeout: { response: getMinutesToMilliseconds(5) }
    };

    this.props.loadAppealDocCount(this.props.externalId);

    const tryFetchingDocumentCount = () => {
      ApiUtil.get(`/appeals/${this.props.externalId}/document_count`, requestOptions).then((response) => {
        const docCount = response.body.document_count;

        // if we were told "try again later" then do do.
        if (response.status === 202 && parseInt(docCount, 10) === -1) {
          // try again in 30 seconds
          setTimeout(tryFetchingDocumentCount, 30000);

          return;
        }

        this.props.setAppealDocCount(this.props.externalId, docCount);
      }, () => {
        this.props.errorFetchingDocumentCount(this.props.externalId);
      });
    };

    tryFetchingDocumentCount();
  }

  render = () => {
    const {
      docCountForAppeal,
      loadingText
    } = this.props;

    if (docCountForAppeal) {
      if (docCountForAppeal.docCountText) {
        return docCountForAppeal.docCountText;
      } else if (loadingText && (docCountForAppeal.loading || docCountForAppeal.error)) {
        return docCountForAppeal.error || <span {...documentCountStyling}>Loading number of docs...</span>;
      }
    }

    return null;
  }
}

AppealDocumentCount.propTypes = {
  appeal: PropTypes.object.isRequired,
  docCountForAppeal: PropTypes.shape({
    docCountText: PropTypes.number,
    loading: PropTypes.bool,
    error: PropTypes.bool
  }),
  errorFetchingDocumentCount: PropTypes.func,
  externalId: PropTypes.string,
  loadAppealDocCount: PropTypes.func,
  loadingText: PropTypes.bool,
  setAppealDocCount: PropTypes.func
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
