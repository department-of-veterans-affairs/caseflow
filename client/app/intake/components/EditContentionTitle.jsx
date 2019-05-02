import React from 'react';
import COPY from '../../../COPY.json';
import TextareaField from '../../components/TextareaField';
import Button from '../../components/Button';
import { css } from 'glamor';

const buttonStyling = css({
  marginBottom: '15px'
});

const paragraphyStyling = css({
  paddingLeft: '30px'
});

const linkStyle = css({
  paddingLeft: '0px'
});

export default class EditContentionTitle extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      showEditTitle: false
    };
  }

  editContentionOnClick = () => {
    this.setState({ showEditTitle: true });
  }

hideEditContentionTileOnClick = () => {
  this.setState({ showEditTitle: false });
}

render() {
  const title = `${this.props.issueIdx + 1}. Contention title `;

  return <div>
    {!this.state.showEditTitle && <div className="issue-edit-text">
      <Button
        onClick={this.editContentionOnClick}
        classNames={['cf-btn-link']}
        styling={linkStyle}
      >
        {COPY.INTAKE_EDIT_TITLE}
      </Button>
    </div>}
    {this.state.showEditTitle && <div className="issue-text-style">
      <TextareaField
        name={title}
        onChange={(value) => {
          this.setState({ value });
        }}
        strongLabel
      />
      <p {...paragraphyStyling}>{this.props.issue.text}</p>
      {this.props.issue.notes && <p {...css({
        fontStyle: 'italic',
        paddingLeft: '30px' })}>Notes: {this.props.issue.notes}</p>}
      <div className="issue-text-buttons">
        {this.state.showEditTitle && <Button
          classNames={['cf-btn-link']}
          onClick={this.hideEditContentionTileOnClick}
        >
            Cancel
        </Button>
        }
        <Button
          name="submit-issue"
          classNames={['cf-submit']}
          onClick={(value) => {
            this.setState({ value });
          }}
          styling={buttonStyling}
        >
            Submit
        </Button>
      </div>
    </div>
    }
  </div>;
}
}

