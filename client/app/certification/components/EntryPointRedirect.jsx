import React from 'react';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';

class EntryPointRedirect extends React.Component {
  render() {
    let {
      match
    } = this.props;

    return <Redirect to={`/certifications/${match.params.vacols_id}/check_documents`} />;
  }
}

export default connect()(EntryPointRedirect);
