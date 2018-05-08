import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../util/ApiUtil';

import { setAppealDocCount } from './QueueActions';

class AppealDocumentCount extends React.PureComponent {
  componentDidMount = () => {
    const appeal = this.props.appeal.attributes;

    if (!this.props.docCountForAppeal) {
      const requestOptions = {
        withCredentials: true,
        timeout: true,
        headers: { 'FILE-NUMBER': appeal.vbms_id }
      };

      ApiUtil.get(appeal.number_of_documents_url, requestOptions).then((response) => {
        const resp = JSON.parse(response.text);

        this.props.setAppealDocCount(appeal.vacols_id, resp.data.attributes.documents.length);
      });
    }
  }

  render = () => this.props.docCountForAppeal;
}

AppealDocumentCount.propTypes = {
  appeal: PropTypes.object.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  docCountForAppeal: state.queue.docCountForAppeal[ownProps.appeal.attributes.vacols_id] || null
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setAppealDocCount
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AppealDocumentCount);
