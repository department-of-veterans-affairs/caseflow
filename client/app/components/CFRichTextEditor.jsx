import React from 'react';
import PropTypes from 'prop-types';
import RichTextEditor from 'react-rte';
import { convertToRaw } from 'draft-js';
import draftToMarkdown from 'draftjs-to-markdown';
import { Editor } from 'react-draft-wysiwyg';

export default class CFRichTextEditor extends React.PureComponent {

  constructor(props) {
    super(props);
    this.state = {
      value: RichTextEditor.createEmptyValue(),
      editorState: undefined
    };
  }

  static getDerivedStateFromProps(nextProps) {
    const { value } = nextProps;

    console.log(value);
    if (value) {
      this.setState({ value });
    }
  }

  onChange = (value) => {
    console.log(draftToMarkdown(this.state.editorState));
    this.setState({ value, editorState: value });
    if (this.props.onChange) {
      // Send the changes up to the parent component as an HTML string.
      // This is here to demonstrate using `.toString()` but in a real app it
      // would be better to avoid generating a string on each change.
      this.props.onChange(value.toString('markdown'));
    }
  };

  render() {
    const {
      errorMessage,
      hideLabel,
      id,
      maxlength,
      label,
      name,
      required,
      type,
      value,
      styling
    } = this.props;
    
    return <div>
      {/* <RichTextEditor onChange={this.onChange} value={this.state.value} /> */}
      <Editor
        wrapperClassName="home-wrapper"
        editorClassName="home-editor"
        onEditorStateChange={this.onChange}
        editorState={this.state.editorState}
      />
      <textarea
          disabled
          className="demo-content no-focus"
          value={this.state.editorState && draftToMarkdown(this.state.editorState.getCurrentContent())}
      />
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
