import React, { PropTypes } from 'react';
import DocumentsCheckTable from './DocumentsCheckTable';
import DocumentsCheckSuccess from './DocumentsCheckSuccess';

export default class Certification extends React.Component {
  constructor(props) {
    super(props);
    this.certification = JSON.stringify(this.props.certification);
  }

  render() {
    // TODO: install a router
    return <div>
      <DocumentsCheckSuccess/>
    </div>;
  }
}
