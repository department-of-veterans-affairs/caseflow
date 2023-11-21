// import React, { useState , useEffect } from 'react';
// import PropTypes from 'prop-types';
// import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
// import Modal from 'app/components/Modal';
// import Button from 'app/components/Button';
// import COPY from '../../../COPY';
// import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';


// function SaveLeverChanges(leverStore)  {
//   leverStore.dispatch({
//     type: Constants.SAVE_LEVERS,
//   });
// };

// function DisplayButtonLeverAlert(alert) {
//   console.log("alert", alert)
//   //show small banner displaying the alert
// };

// function UpdateInitialLevers(leverStore) {

// }

// function UpdateLeverHistory(leverStore) {
//   // create history row object
//   // append history row object to formatted_history array
//   // save history row object to database
//   // refresh lever div
// };
// function SaveLeversToDB(leverStore) {
//   console.log('Will be saving the following to the table')
//   //load the levers from leverStore.getState().levers into the DB
// };

// export function LeverSaveButton({ leverStore }) {
//   const [showModal, setShowModal] = useState(false);
//   const [isSaveButtonActive, setIsSaveButtonActive] = useState(false);
//   const [isSaving, setIsSaving] = useState(false);

//   useEffect(() => {
//     const levers = leverStore.getState().levers;
//     const initialLevers = leverStore.getState().initial_levers;
//     const hasStateChanged = JSON.stringify(levers) !== JSON.stringify(initialLevers);
//     setIsSaveButtonActive(hasStateChanged);
//   }, [leverStore]);

//   const handleSave = () => {
//     setShowModal(true);
//   };

//   const handleConfirm = async () => {
//     setIsSaving(true);
//     try {
//       await SaveLeverChanges(leverStore);
//       DisplayButtonLeverAlert('Save Successful')
//     } catch (error) {
//       DisplayButtonLeverAlert('Save Failed')
//     } finally {
//       setIsSaving(false);
//       setShowModal(false);
//     }
//   };

//   const handleCancel = () => {
//     setShowModal(false);
//   };
//   const levers = () => {
//     return leverStore.getState().levers;
//   }
//   const leverListTable = (
//     <table>
//           <tbody>
//             <tr>
//               <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableLeftStyling}`}>Data Element</th>
//               <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableRightStyling}`}>Previous Value</th>
//               <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableRightStyling}`}>New Value</th>
//             </tr>
//           </tbody>
//           <tbody>
//             {!levers && levers.map((lever, index) => (
//               <tr key={index}>
//                 <td className={`${styles.modalTableStyling} ${styles.modalTableLeftStyling}`}>{lever.title}</td>
//                 <td className={`${styles.modalTableStyling} ${styles.modalTableRightStyling}`}>
//                 {leverStore.getState().initial_levers[index].value}
//                 </td>
//                 <td className={`${styles.modalTableStyling} ${styles.modalTableRightStyling}`}><strong>{lever.value}</strong></td>
//               </tr>
//             ))}
//           </tbody>
//         </table>
//   )


//   return (
//     <>
//       <Button id="SaveLeversButton" onClick={handleSave} disabled={!isSaveButtonActive || isSaving}>
//         Save
//       </Button>
//       {showModal &&
//       <Modal
//         isOpen={showModal}
//         onClose={handleCancel}
//         title={COPY.CASE_DISTRIBUTION_MODAL_TITLE}
//         confirmButton={<Button onClick={handleConfirm}>{COPY.MODAL_CONFIRM_BUTTON}</Button>}
//         cancelButton={<Button onClick={handleCancel}>{COPY.MODAL_CANCEL_BUTTON}</Button>}
//         className={styles.updatedModalStyling}
//       >
//         <p>{COPY.CASE_DISTRIBUTION_MODAL_DESCRIPTION}</p>
//         {leverListTable}
//       </Modal>
//       }
//     </>
//   );
// }

// LeverSaveButton.propTypes = {
//   leverStore: PropTypes.any,
// };

import React, { useState } from 'react';
import PropTypes from 'prop-types';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import Modal from 'app/components/Modal';
import Button from 'app/components/Button';
import COPY from '../../../COPY';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';


function SaveLeverChanges(leverStore)  {
  leverStore.dispatch({
    type: Constants.SAVE_LEVERS,
  });
};

function DisplayButtonLeverAlert(alert) {
  console.log("alert", alert)
  //show small banner displaying the alert
};
function UpdateLeverHistory(leverStore) {
  // create history row object
  // append history row object to formatted_history array
  // save history row object to database
  // refresh lever div
};
function SaveLeversToDB(leverStore) {
  //load the levers from leverStore.getState().levers into the DB
};
function DisableSaveButton() {
  document.getElementById("SaveLeversButton").disabled = true;
};

function leverList(leverStore) {
  const levers = leverStore.getState().levers;
  const initialLevers = leverStore.getState().initial_levers;

  return (
    <div>
      <table>
        <tbody>
          <tr>
            <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableLeftStyling}`}>Data Element</th>
            <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableRightStyling}`}>Previous Value</th>
            <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableRightStyling}`}>New Value</th>
          </tr>
        </tbody>
        <tbody>
          {levers.map((lever, index) => (
            <tr key={index}>
              {lever.value !== initialLevers[index].value && (
                <React.Fragment>
              <td className={`${styles.modalTableStyling} ${styles.modalTableLeftStyling}`}>{lever.title}</td>
              <td className={`${styles.modalTableStyling} ${styles.modalTableRightStyling}`}>{initialLevers[index].value}</td>
              <td className={`${styles.modalTableStyling} ${styles.modalTableRightStyling}`}><strong>{lever.value}</strong></td>
                </React.Fragment>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function LeverSaveButton({ leverStore }) {
  const [showModal, setShowModal] = useState(false);

  const handleSave = () => {
    SaveLeversToDB(leverStore);
    //     UpdateInitialLevers(leverStore);
    //     UpdateLeverHistory(leverStore);
    //     setShowModal(true);
    UpdateLeverHistory(leverStore);
    SaveLeverChanges(leverStore);
    DisableSaveButton();
    setShowModal(false);
    DisplayButtonLeverAlert('');
  };



  return (
    <>
      <Button id="SaveLeversButton" onClick={() => setShowModal(true)}>
        Save
      </Button>
      {showModal &&
      <Modal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        title={COPY.CASE_DISTRIBUTION_MODAL_TITLE}
        confirmButton={<Button onClick={handleSave}>{COPY.MODAL_CONFIRM_BUTTON}</Button>}
        cancelButton={<Button onClick={() => setShowModal(false)}>{COPY.MODAL_CANCEL_BUTTON}</Button>}
        className={styles.updatedModalStyling}
      >
        <p>{COPY.CASE_DISTRIBUTION_MODAL_DESCRIPTION}</p>
        {leverList(leverStore)}
      </Modal>
      }
    </>
  );
}

LeverSaveButton.propTypes = {
  leverStore: PropTypes.any,
};
