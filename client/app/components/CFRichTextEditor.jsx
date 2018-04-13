import React from 'react';
import PropTypes from 'prop-types';
import { convertToRaw, EditorState, ContentState } from 'draft-js';
import draftToHtml from 'draftjs-to-html';
import htmlToDraft from 'html-to-draftjs';
import { Editor } from 'react-draft-wysiwyg';
import classNamesFn from 'classnames';
import { css } from 'glamor';

const styles = css({
  border: '1px solid #323a45',
  // overflow: 'auto',
  resize: 'vertical'
});

// Bold
// Italic
// Underline
// font size
// bullets
// numbered list
// font color: we could limit this to 3 - blue, black and red
const toolbar = {
  options: ['inline', 'fontSize', 'list', 'colorPicker', 'link'],
  inline: {
    inDropdown: false,
    className: undefined,
    component: undefined,
    dropdownClassName: undefined,
    options: ['bold', 'italic', 'underline']
  },
  fontSize: {
    options: [8, 9, 10, 11, 12, 14, 16, 18, 24, 30, 36, 48, 60, 72, 96],
    className: undefined,
    component: undefined,
    dropdownClassName: undefined,
  },
  list: {
    inDropdown: false,
    className: undefined,
    component: undefined,
    dropdownClassName: undefined,
    options: ['unordered', 'ordered'],
    title: undefined,
  },
  colorPicker: {
    className: undefined,
    component: undefined,
    popupClassName: undefined,
    options: ['Text'],
    colors: ['rgb(0,0,0)', 'rgb(0,0,255)', 'rgb(255,0,0)'],
  }
};

export default class CFRichTextEditor extends React.PureComponent {

  constructor(props) {
    super(props);
    this.state = {
      editorState: EditorState.createEmpty()
    };
  }

  componentDidMount = () => {
    const { value } = this.props;
    const contentBlock = htmlToDraft(value);

    const contentState = ContentState.createFromBlockArray(contentBlock.contentBlocks);
    const editorState = EditorState.createWithContent(contentState);

    if (value) {
      this.setState({ editorState });
    }
  };

  onChange = (value) => {
    this.setState({
      value,
      editorState: value
    });

    if (this.props.onChange) {
      // Send the changes up to the parent component as an HTML string.
      // This is here to demonstrate using `.toString()` but in a real app it
      // would be better to avoid generating a string on each change.
      // this.props.onChange(value.toString('markdown'));
      this.props.onChange(draftToHtml(convertToRaw(this.state.editorState.getCurrentContent())));
    }
  };

  render() {
    const {
      errorMessage,
      hideLabel,
      id,
      label,
      name,
      required
    } = this.props;
    
    return <div>
      <label className={classNamesFn({ 'sr-only': hideLabel }, 'question-label')} htmlFor={id || name}>
        {label || name} {required && <span className="cf-required">Required</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <div {...styles}>
        <Editor
          onEditorStateChange={this.onChange}
          editorState={this.state.editorState}
          editorClassName="other-editor"
          toolbar={toolbar}
        />
      </div>
    </div>;
  }
}

CFRichTextEditor.propTypes = {
  sections: PropTypes.arrayOf(
    PropTypes.shape({
      activated: PropTypes.boolean,
      title: PropTypes.string
    })
  )
};
