import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/Dockets';

export class TextareaContainer extends React.Component {

  updateTextarea = (event) => {
    this.props.updateTextarea(this.props.action, this.props.id, event.target.value);
  }

  render() {
    return <textarea
      id={this.props.id}
      defaultValue={this.props[this.props.id] || this.props.defaultValue || ''}
      onChange={this.updateTextarea}
      maxLength={this.props.maxLength}
      tabIndex={this.props.tabIndex}
    />;
  }
}

const mapDispatchToProps = (dispatch) => ({
  updateTextarea: (actionName, prop, value) => {
    dispatch(Actions[actionName](prop, value));
  }
});

export default connect(
  null,
  mapDispatchToProps
)(TextareaContainer);

TextareaContainer.propTypes = {
  id: PropTypes.string.isRequired
};
