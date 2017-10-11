import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';

import Button from '../components/Button';
import _ from 'lodash';

import { connect } from 'react-redux';

import { createAnnotation, requestEditAnnotation } from '../reader/actions';

// A rounded rectangle with a text box for adding
// or editing an existing comment.
class EditComment extends React.Component {

  constructor(props) {
    super(props);

    this.shouldAutosave = true;
  }

  handleAutoSave = () => {
    // only autosave when a comment exists
    if (this.shouldAutosave && this.props.comment.comment) {
      this.onSaveCommentEdit();
    }
  }

  getActiveEditingComment = () => this.props.comment.id;

  handleAltEnter = () => {
    this.shouldAutosave = false;
    if (this.props.placedButUnsavedAnnotation) {
      this.props.createAnnotation(this.props.placedButUnsavedAnnotation);
    } else if (this.props.editingAnnotations) {
      this.props.requestEditAnnotation(this.props.editingAnnotations[this.getActiveEditingComment()]);
    }
  }

  keyListener = (event) => {
    if (event.altKey) {
      if (event.code === 'Enter') {
        this.handleAltEnter();
      }
    }
  }

  componentDidMount = () => {
    let commentBox = document.getElementById(this.props.id);

    commentBox.focus();

    // ensure we autosave if we ever exit
    window.addEventListener('beforeunload', this.handleAutoSave);
    window.addEventListener('keydown', this.keyListener);
  }

  componentWillUnmount() {
    window.removeEventListener('beforeunload', this.handleAutoSave);
    window.removeEventListener('keydown', this.keyListener);
    this.handleAutoSave();
  }


  onChange = (event) => this.props.onChange(event.target.value, this.props.comment.uuid);

  onCancelCommentEdit = () => {
    this.shouldAutosave = false;
    this.props.onCancelCommentEdit(this.props.comment.uuid);
  }

  onSaveCommentEdit = () => {
    this.shouldAutosave = false;
    this.props.onSaveCommentEdit(this.props.comment);
  }

  render() {
    return <div>
        <textarea
          className="comment-container comment-textarea"
          name="Edit Comment"
          aria-label="Edit Comment"
          onFocus={this.getActiveEditingComment}
          id={this.props.id}
          onChange={this.onChange}
          value={this.props.comment.comment}
        />
        <div className="comment-save-button-container">
          <span className="cf-right-side">
            <Button
              name="cancel"
              classNames={['cf-btn-link']}
              onClick={this.onCancelCommentEdit}>
              Cancel
            </Button>
            <Button
              disabled={this.props.disableOnEmpty && !this.props.comment.comment}
              name="save"
              onClick={this.onSaveCommentEdit}>
              Save
            </Button>
          </span>
        </div>
      </div>;
  }
}

const mapStateToProps = (state) => {
  return {
    ..._.pick(state.readerReducer.ui, 'placedButUnsavedAnnotation'),
    ..._.pick(state.readerReducer, 'editingAnnotations')
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    createAnnotation,
    requestEditAnnotation
  }, dispatch)
});


EditComment.defaultProps = {
  id: 'commentEditBox'
};

EditComment.propTypes = {
  comment: PropTypes.object.isRequired,
  disableOnEmpty: PropTypes.bool,
  id: PropTypes.string,
  onSaveCommentEdit: PropTypes.func,
  onCancelCommentEdit: PropTypes.func
};

export default connect(
  mapStateToProps, mapDispatchToProps
)(EditComment);
