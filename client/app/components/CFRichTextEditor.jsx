import React from 'react';
import PropTypes from 'prop-types';
import RichTextEditor from 'react-rte';
import { convertToRaw } from 'draft-js';
import draftToMarkdown from 'draftjs-to-markdown';
// import { markdownToDraft } from 'markdown-to-draftjs';
import draftToHtml from 'draftjs-to-html';
import htmlToDraft from 'html-to-draftjs';

import { stateFromMarkdown } from 'draft-js-import-markdown';

import { Editor } from 'react-draft-wysiwyg';
import { EditorState, ContentState } from 'draft-js';

export default class CFRichTextEditor extends React.PureComponent {

  constructor(props) {
    super(props);
    this.state = {
      value: RichTextEditor.createEmptyValue(),
      editorState: EditorState.createEmpty()
    };
  }

  // componentWillReceiveProps(nextProps) {
  //   const { value } = nextProps;

  //   console.log(draftToMarkdown(value));
  //   if (value) {
  //     this.setState({ value });
  //   }
  // }

  componentDidMount = () => {
    const { value } = this.props;

    console.log(htmlToDraft(value));

    const contentBlock = htmlToDraft(value);

    const contentState = ContentState.createFromBlockArray(contentBlock.contentBlocks);
    const editorState = EditorState.createWithContent(contentState);

    if (value) {
      this.setState({ editorState });
    }
  };

  onChange = (value) => {
    console.log(draftToMarkdown(convertToRaw(this.state.editorState.getCurrentContent())));
    this.setState({ value, editorState: value });
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
