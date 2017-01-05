import React, { PropTypes } from 'react';

import SearchableDropDown from '../components/SearchableDropDown';
import Table from '../components/Table';
import Button from '../components/Button';
import ApiUtil from '../util/ApiUtil';
import PdfViewer from '../components/PdfViewer';


import {
          FormField,
          handleFieldChange,
          getFormValues,
          validateFormAndSetErrors
       } from '../util/FormField';

export default class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {pdf: 0};

  }

  componentDidMount() {
    window.addEventListener('keydown', (e) => {
      console.log('here!');
      console.log(this.state);
      if (e.key == 'ArrowLeft') {
        this.setState({pdf: Math.max(this.state.pdf - 1, 0)});
      }
      if (e.key == 'ArrowRight') {
        this.setState({pdf: Math.min(this.state.pdf + 1, this.props.pdfLinks.length - 1)});
      }
    });
  }

  render() {
    let { pdfLinks } = this.props;

    return (
      <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Review Decision</h2>
          Review the final decision from VBMS below to determine the next step.
        </div>

        <PdfViewer
          file={pdfLinks[this.state.pdf]} />

      </div>
    );
  }
}