import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { MTVAttorneyDisposition } from './MTVAttorneyDisposition';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import { fetchJudges } from '../QueueActions';
import { submitMTVAttyReview } from './mtvActions';
import { taskById, appealWithDetailSelector } from '../selectors';

export const ReviewMotionToVacateView = (props) => {
  const { task, appeal } = props;

  const judgeOptions = Object.values(judges).map(({ id, display_name }) => ({ label: display_name,
    value: id }));

  const handleSubmit = (review) => {
    console.log('handleSubmit', review);
    props.submitMTVAttyReview(review);
  };

  useEffect(() => {
    if (!judgeOptions.length) {
      props.fetchJudges();
    }
  });

  return judges && <MTVAttorneyDisposition task={task} judges={judgeOptions} appeal={appeal} onSubmit={handleSubmit} />;
};

// class SendToJudgeView extends React.Component {
//   constructor(props) {
//     super(props);
// console.log(props)
//     this.state = {
//       disposition: null,
//       selectedJudge: null,
//       linkToDraft: null,
//       instructions: null
//     };
//   }
//
//   render = () => {
//     return <div>Hi</div>;
//   };
// }

// ReviewMotionToVacateView.propTypes = {
//   task: PropTypes.object,
//   appeal: PropTypes.object,
//   judges: PropTypes.array,
//   fetchJudges: PropTypes.func,
//   submitMTVAttyReview: PropTypes.func
// };

const mapStateToProps = (state, ownProps) => {
  return {
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps),
    // judges: state.queue.judges
  };
};

// const mapDispatchToProps = (dispatch) =>
//   bindActionCreators(
//     {
//       fetchJudges,
//       submitMTVAttyReview
//     },
//     dispatch
//   );

export default withRouter(
  connect(
    mapStateToProps,
    // mapDispatchToProps
  )(SendToJudgeView)
);
