import React, { PropTypes } from 'react';
import Button from '../components/Button';

// A rounded rectangle with a text box for adding
// or editing an existing comment.
export default class EditComment extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: this.props.children
    };
  }

  onChange = (event) => {
    this.setState({
      value: event.target.value
    });
  }

  resetForm = () => {
    this.setState({
      value: ''
    });
  }

  cancelEdit = () => {
    this.props.onCancelCommentEdit();
    this.resetForm();
  }

  onSaveCommentEdit = () => {
    this.props.onSaveCommentEdit(
      this.state.value, this.props.uuid);
    this.resetForm();
  }

  // If we receive a new 'children' prop, we use it as the text
  // in the edit form.
  componentWillReceiveProps(nextProps) {
    if (nextProps.children !== this.props.children) {
      this.setState({
        value: nextProps.children
      });
    }
  }

  componentDidMount = () => {
    let commentBox = document.getElementById(this.props.id);

    commentBox.focus();
  }

  render() {
    return <div>
        <textarea
          className="comment-container comment-textarea"
          name="Edit Comment"
          aria-label="Edit Comment"
          id={this.props.id}
          onChange={this.onChange}
          value={this.state.value}
        />
        <div className="comment-control-button-container">
          <span className="cf-right-side">
            <Button
              name="cancel"
              classNames={['cf-btn-link']}
              onClick={this.cancelEdit}>
              Cancel
            </Button>
            <Button
              name="save"
              onClick={this.onSaveCommentEdit}>
              Save
            </Button>
          </span>
        </div>
      </div>;
  }
}

EditComment.defaultProps = {
  id: 'commentEditBox'
};

EditComment.propTypes = {
  children: React.PropTypes.string,
  id: React.PropTypes.string,
  onSaveCommentEdit: PropTypes.func,
  onCancelCommentEdit: PropTypes.func
};
