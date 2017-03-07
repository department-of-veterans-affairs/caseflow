import React, { Component } from 'react';

export default class Accordion extends React.Component{
  constructor(props) {
    super(props);
    this.state = { toggle: true };
  }

  toggleButton() {
    this.setState({toggle: !this.state.toggle})
  }

  render() {
    let {
      title,
      content
    } = this.props;

    let {
      toggle
    } = this.state;

    return (
      <div>
        <button className="usa-accordion-button"
          aria-expanded={!toggle} aria-controls="react-code" onClick={() => this.toggleButton()}>
          {title}
        </button>
        <div id="react-code" className="usa-accordion-content" aria-hidden={toggle}>
          {content}
        </div>
      </div>
    )
  }
}
