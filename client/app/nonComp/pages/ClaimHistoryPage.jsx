import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import NonCompLayout from '../components/NonCompLayout';
import Link from 'app/components/Link';

class ClaimHistoryPageUnconnected extends React.PureComponent {

  render = () => {
    const { task } = this.props;

    const returnLink = `${task.tasks_url}/tasks/${task.id}`;

    return <>
      <Link href={returnLink}><b><u>&lt; Back to Decision Review</u></b></Link>
      <NonCompLayout>
        <h1>{task.claimant.name}</h1>
      </NonCompLayout>
    </>;
  }
}

ClaimHistoryPageUnconnected.propTypes = {
  task: PropTypes.shape({
    id: PropTypes.number,
    claimant: PropTypes.object,
    tasks_url: PropTypes.string,
    type: PropTypes.string,
    created_at: PropTypes.string
  }),
};

const ClaimHistoryPage = connect(
  (state) => ({
    task: state.nonComp.task,
  })
)(ClaimHistoryPageUnconnected);

export default ClaimHistoryPage;
