import React, {PureComponent} from 'react';
import { bindActionCreators } from 'redux';
import ToggleButton from '../components/ToggleButton';
import Button from '../components/Button';
import { connect } from 'react-redux';
import { setViewingDocumentsOrComments } from './actions';

class DocumentsCommentsButton extends PureComponent {
  render() {
    return <div className="cf-documents-comments-control">
      <span className="cf-show-all-label">Show all:</span> 
      <ToggleButton 
        active={this.props.viewingDocumentsOrComments} 
        onClick={this.props.setViewingDocumentsOrComments}>

        <Button name="documents" style={{marginLeft: 0}}>
          Documents
        </Button>
        <Button name="comments" style={{marginRight: 0}}>
          Comments
        </Button>
      </ToggleButton>
    </div>;
  }
}

export default connect(
  (state) => ({
    viewingDocumentsOrComments: state.viewingDocumentsOrComments
  }),
  (dispatch) => bindActionCreators({
    setViewingDocumentsOrComments
  }, dispatch)
)(DocumentsCommentsButton);
