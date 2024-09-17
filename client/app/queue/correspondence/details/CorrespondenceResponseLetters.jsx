import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import Button from '../../../components/Button';
import QueueFlowModal from '../../components/QueueFlowModal';
import NewLetter from '../intake/components/AddCorrespondence/NewLetter';
import {
  submitLetterResponse
} from '../../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

const CorrespondenceResponseLetters = (props) => {
  const {
    letters,
    isInboundOpsSuperuser,
    isInboundOpsSupervisor,
    isInboundOpsUser
  } = props;

  const [showAddLetterModal, setShowAddLetterModal] = useState(false);
  const [ dataLetter, setDataLetter] = useState([]);
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

  const filterNewLetters = () => {
    // Filter out letters that already have an id (existing letters)
    return dataLetter.filter((letter) => !letter.id);
  };

  const handleSubmitFunction = () => {
    setShowAddLetterModal(false);
    setIsFormComplete(false);

    const newLetters = filterNewLetters();
    const payload = {
      data: {
        response_letters: newLetters
      }
    };

    if (typeof props.submitLetterResponse === 'function') {
      props.submitLetterResponse(payload, props.correspondence)
        .then((response) => {
          const newLetterFromResponse = response.correspondence;
          const updatedLetters = [...letters, ...newLetterFromResponse];
          console.log("Updated letters:", updatedLetters);
          setDataLetter(updatedLetters);
        })
        .catch((error) => {
          console.error('Error submitting letter response:', error);
        });
    } else {
      console.error('submitLetterResponse is not a function');
    }
  };

  return (
    <div className="correspondence-package-details">
      <h2 className="correspondence-h2">
        <strong>Response Letter</strong>
        <span className="response-letter-button-styling">
          {canAddLetter && letters.length < 3 && (
            <Button
              type="button"
              onClick={handleAddLetterClick}
              disabled= {!(letters.length < 3)}
              name="addLetter"
              classNames={['cf-left-side']}>
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
          setUnrelatedTasksCanContinue= {() => {}}
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
  letters: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      correspondence_id: PropTypes.number,
      letter_type: PropTypes.string,
      title: PropTypes.string,
      subcategory: PropTypes.string,
      reason: PropTypes.string,
      date_sent: PropTypes.string,
      response_window: PropTypes.number,
      user_id: PropTypes.number,
      days_left: PropTypes.string,
      expired: PropTypes.oneOfType([
        PropTypes.string,
        PropTypes.bool
      ]),
    })
  ).isRequired,
  isInboundOpsSuperuser: PropTypes.bool.isRequired,
  isInboundOpsSupervisor: PropTypes.bool.isRequired,
  isInboundOpsUser: PropTypes.bool.isRequired,
  addLetterCheck: PropTypes.bool.isRequired,
  addButtonCheck: PropTypes.bool.isRequired,
  correspondence: PropTypes.object,
  submitLetterResponse: PropTypes.func.isRequired
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  submitLetterResponse: (payload, correspondence) => submitLetterResponse(payload, correspondence)
}, dispatch);

export default withRouter(
  connect(
    null,
    mapDispatchToProps
  )(CorrespondenceResponseLetters)
);
