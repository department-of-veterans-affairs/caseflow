import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { NewFileIcon } from '../../components/RenderFunctions';
import { bindActionCreators } from 'redux';
import { getNewDocuments } from '../QueueActions'

class NewFile extends React.Component {
  componentDidMount = () => {
    if (!this.props.docs) {
      this.props.getNewDocuments(this.props.appeal.attributes.vacols_id);
    }
  }

  render = () => {
    if (this.props.docs && this.props.docs.length > 0) {
      return <NewFileIcon />;
    } else {
      return null
    }
  }
}

NewFile.propTypes = {
  appeal: PropTypes.shape({
    attributes: PropTypes.shape({
      vacols_id: PropTypes.string
    })
  }).isRequired,
  documentObject: PropTypes.shape({
    docs: PropTypes.object,
    error: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => {
  const documentObject = state.queue.newDocsForAppeal[ownProps.appeal.attributes.vacols_id];

  return {
    docs: documentObject ? documentObject.docs : null,
    error: documentObject ? documentObject.error : null
  };
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getNewDocuments
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(NewFile);
