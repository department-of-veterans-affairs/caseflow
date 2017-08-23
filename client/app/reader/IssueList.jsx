import PropTypes from 'prop-types';

const IssueList = (appeal) => (
  appeal.issues.map((issue) =>
    <li key={`${issue.appeal_id}_${issue.vacols_sequence_id}`}><span>
      {issue.type.label}: {issue.levels ? issue.levels.join(', ') : ''}
    </span></li>
  )
);

IssueList.propTypes = {
  appeal: PropTypes.object
};

export default IssueList;
