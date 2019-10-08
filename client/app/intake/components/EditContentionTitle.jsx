import React from 'react';
import COPY from '../../../COPY.json';
import TextareaField from '../../components/TextareaField';
import Button from '../../components/Button';
import { css } from 'glamor';
import { setEditContentionText } from '../actions/addIssues';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

export class EditContentionTitle extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      showEditTitle: false,
      editedDescription: props.issue.editedDescription ? this.props.issue.editedDescription : this.props.issue.text
    };
  }

  editContentionOnClick = () => {
    this.setState({ showEditTitle: true });
  }

  hideEditContentionOnClick = () => {
    this.setState({ showEditTitle: false });
  }

  editContentionTextOnChange = (value) => {
    this.setState({
      editedDescription: value
    });
  }

  onClickSaveEdit = () => {
    this.props.setEditContentionText(this.props.issueIdx, this.state.editedDescription);
    this.setState({ showEditTitle: false });
  }

  render() {
    const title = `${this.props.issueIdx + 1}. Contention title `;

    return <div>
      { !this.state.showEditTitle && <div className="issue-edit-text">
        <Button
          onClick={this.editContentionOnClick}
          classNames={['cf-btn-link', 'edit-contention-issue']}
        >
          {COPY.INTAKE_EDIT_TITLE}
        </Button>
      </div> }

      { this.state.showEditTitle && <div className="issue-text-style">
        <TextareaField
          name={title}
          placeholder={this.props.issue.editedDescription ? this.props.issue.editedDescription : this.props.issue.text}
          onChange= {this.editContentionTextOnChange}
          value={this.state.editedDescription}
          strongLabel
        />
        <p>{this.props.issue.editedDescription ? this.props.issue.editedDescription : this.props.issue.text}</p>
        {this.props.issue.notes && <p {...css({
          fontStyle: 'italic' })}>Notes: {this.props.issue.notes}</p>}
        <div className="issue-text-buttons">
          {this.state.showEditTitle && <Button
            classNames={['cf-btn-link']}
            onClick={this.hideEditContentionOnClick}
          >
                Cancel
          </Button>
          }
          <Button
            name="submit-issue"
            classNames={['cf-submit', 'issue-edit-submit-button']}
            disabled={!this.state.editedDescription}
            onClick={this.onClickSaveEdit}
          >
                Submit
          </Button>
        </div>
      </div> }
    </div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setEditContentionText
}, dispatch);

export default connect(null, mapDispatchToProps
)(EditContentionTitle);
