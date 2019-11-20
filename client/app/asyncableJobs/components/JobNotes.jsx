import React from 'react';
import Button from '../../components/Button';
import ApiUtil from '../../util/ApiUtil';
import PropTypes from 'prop-types';
import moment from 'moment';
import ReactMarkdown from 'react-markdown';

const DATE_TIME_FORMAT = 'ddd MMM DD HH:mm:ss YYYY';

import Checkbox from '../../components/Checkbox';
import TextareaField from '../../components/TextareaField';

class NewNoteForm extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      saveInProgress: false,
      checkboxSelected: true,
      newNote: ''
    };
  }

  onSave = () => {
    const job = this.props.job;
    const url = `/asyncable_jobs/${job.klass}/jobs/${job.id}/note`;
    const form = this;
    const notes = this.props.notes;

    const data = {
      note: this.state.newNote,
      send_to_intake_user: this.state.checkboxSelected
    };

    notes.setState({ reloaded: false });

    ApiUtil.post(url, { data }).
      then(
        (response) => {
          const newNote = JSON.parse(response.text);

          form.setState({
            saveInProgress: false,
            checkboxSelected: false,
            newNote: ''
          });

          // add note to current page.
          notes.props.notes.unshift(newNote);
          notes.setState({ reloaded: true });
        }
      );
  }

  onChange = (event) => {
    this.setState({ newNote: event });
  }

  onCheckboxChange = (event) => {
    this.setState({ checkboxSelected: event });
  }

  isSaveDisabled = () => {
    return this.state.saveInProgress || this.state.newNote.trim().length === 0;
  }

  isCheckboxChecked = () => {
    return this.state.checkboxSelected;
  }

  sendToUserCheckbox = () => {
    return <Checkbox
      label="Send as message to user"
      name="send_to_intake_user"
      value={this.isCheckboxChecked()}
      onChange={this.onCheckboxChange}
      disabled={this.state.saveInProgress}
    />;
  }

  render = () => {
    return <div className="comment-size-container">
      <TextareaField
        hideLabel
        name="Add Note"
        aria-label="Add Note"
        onChange={this.onChange}
        value={this.state.newNote}
      />
      <div className="comment-save-button-container">
        <span className="cf-right-side">
          { this.props.job.user && this.sendToUserCheckbox() }
          <Button
            name="save"
            disabled={this.isSaveDisabled()}
            onClick={this.onSave}>
              Add Note
          </Button>
        </span>
      </div>
    </div>;
  }

}

NewNoteForm.propTypes = {
  job: PropTypes.object,
  notes: PropTypes.object,
  onSave: PropTypes.func,
  onCancel: PropTypes.func
};

export default class JobNotes extends React.PureComponent {

  render = () => {
    const { notes, job } = this.props;

    return <div className="job-notes">
      <h3>Notes</h3>
      <NewNoteForm job={job} notes={this} />
      <div>
        { notes.map((note, index) => {
          return <div className="job-note" key={`job-note-container-${index}`}>
            <div
              className="job-note-details"
              data-key={`job-note-${index}`}
              key={`job-note-${index}`}
              id={`job-note-${note.id}`}>

              <div>
                <span className="job-note-time">{moment(note.created_at).format(DATE_TIME_FORMAT)}</span>
                <span className="job-note-user">{note.user}</span>
              </div>
              <div className="job-note-note"><ReactMarkdown source={note.note} /></div>

            </div>
          </div>;
        })}
      </div>
    </div>;
  }
}

JobNotes.propTypes = {
  job: PropTypes.object,
  notes: PropTypes.array
};
