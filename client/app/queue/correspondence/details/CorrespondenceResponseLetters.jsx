import React, { useState } from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import Button from '../../../components/Button';
import QueueFlowModal from '../../components/QueueFlowModal';
import NewLetter from '../intake/components/AddCorrespondence/NewLetter';
import {
  submitLetterResponse,
  updateCorrespondenceInfo
} from '../../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

const CorrespondenceResponseLetters = (props) => {
  const letters = props.correspondence.correspondenceResponseLetters;
  const {
    isInboundOpsSuperuser,
    isInboundOpsSupervisor,
    isInboundOpsUser
  } = props;

  const [showAddLetterModal, setShowAddLetterModal] = useState(false);
  const [dataLetter, setDataLetter] = useState([]);
  const [isFormComplete, setIsFormComplete] = useState(false);

  const canAddLetter = isInboundOpsUser || isInboundOpsSupervisor || isInboundOpsSuperuser;

  const handleAddLetterClick = () => {
    setShowAddLetterModal(true);
  };

  const handleCloseAddLetterModal = () => {
    setShowAddLetterModal(false);
  };

  const taskUpdatedCallback = (updatedTask) => {
    setDataLetter((prevDataLetter) => [...prevDataLetter.filter((cdl) => cdl.id !== updatedTask.id), updatedTask]);
  };

  const onFormCompletion = (isComplete) => {
    setIsFormComplete(isComplete);
  };

  const handleSubmitFunction = () => {
    setShowAddLetterModal(false);
    setIsFormComplete(false);

    const payload = {
      data: {
        response_letters: dataLetter
      }
    };

    return props.submitLetterResponse(payload, props.correspondence);
  };

  return (
    <div className="correspondence-response-letters">
      <h2 className="correspondence-h2">
        <strong>Response Letter</strong>
        <span className="response-letter-button-styling">
          {canAddLetter && letters.length < 3 && (
            <Button
              type="button"
              onClick={handleAddLetterClick}
              disabled={!(letters.length < 3)}
              name="addLetter"
              classNames={['cf-left-side']}
            >
              + Add letter
            </Button>
          )}
        </span>
      </h2>
      {letters.map((letter, index) => (
        <div key={index}>
          <table className="response-letter-table-borderless-no-background gray-border">
            <tbody>
              <tr>
                <td className="response-letter-table-borderless-first-item">
                  <strong>Letter response expiration:</strong>
                  <span className="response-letter-table-borderless">
                    {letter.days_left}
                  </span>
                </td>
              </tr>
              <tr>
                <th className="response-letter-table-borderless-second-item">
                  <strong>Date response letter sent</strong>
                </th>
                <th className="response-letter-table-borderless-second-item">
                  <strong>Letter type</strong>
                </th>
                <th className="response-letter-table-borderless-second-item">
                  <strong>Letter title</strong>
                </th>
                <th className="response-letter-table-borderless-second-item">
                  <strong>Letter subcategory</strong>
                </th>
                <th className="response-letter-table-borderless-second-item">
                  <strong>Letter subcategory reasons</strong>
                </th>
              </tr>
              <tr>
                <td colSpan="5" className="hr-container">
                  <hr className="full-width-hr" />
                </td>
              </tr>
              <tr>
                <td className="response-letter-table-borderless-last-item">
                  {moment(letter.date_sent).format('MM/DD/YYYY')}
                </td>
                <td className="response-letter-table-borderless-last-item">
                  {letter.letter_type}
                </td>
                <td className="response-letter-table-borderless-last-item">
                  {letter.title}
                </td>
                <td className="response-letter-table-borderless-last-item">
                  {letter.subcategory}
                </td>
                <td className="response-letter-table-borderless-last-item">
                  {letter.reason}
                </td>
              </tr>
              &nbsp;
            </tbody>
          </table>
        </div>
      ))}

      {showAddLetterModal && (
        <QueueFlowModal
          title="Add response letter"
          button="Add"
          type="addLetter"
          name="addLetter"
          submitDisabled={!isFormComplete}
          pathAfterSubmit={`/queue/correspondence/${props.correspondence.uuid}`}
          onCancel={handleCloseAddLetterModal}
          submit={handleSubmitFunction}
        >
          <NewLetter
            setUnrelatedTasksCanContinue={() => true}
            addLetterCheck={props.addLetterCheck}
            taskUpdatedCallback={taskUpdatedCallback}
            onFormCompletion={onFormCompletion}
          />
        </QueueFlowModal>
      )}
    </div>
  );
};

CorrespondenceResponseLetters.propTypes = {
  letters: PropTypes.array.isRequired,
  isInboundOpsSuperuser: PropTypes.bool.isRequired,
  isInboundOpsSupervisor: PropTypes.bool.isRequired,
  isInboundOpsUser: PropTypes.bool.isRequired,
  addLetterCheck: PropTypes.bool.isRequired,
  correspondence: PropTypes.object.isRequired,
  submitLetterResponse: PropTypes.func.isRequired,
};

const mapStateToProps = (state) => ({
  updateCorrespondenceInfo: state.correspondenceDetails.updateCorrespondenceInfo,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateCorrespondenceInfo,
  submitLetterResponse: (payload, correspondence) => submitLetterResponse(payload, correspondence)
}, dispatch);

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CorrespondenceResponseLetters)
);
