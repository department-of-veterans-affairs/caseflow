import React from 'react';
import PropTypes from 'prop-types';

const WorkOrderUnassign = ({ onClose, workOrderNumber, id }) => {
  const styles = {
    modal: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      position: 'fixed',
      top: '50%',
      left: '50%',
      transform: 'translate(-50%, -50%)',
      backgroundColor: 'white',
      padding: '2rem',
      border: '1px solid #ccc',
      borderRadius: '8px',
      boxShadow: '0 2px 10px rgba(0, 0, 0, 0.1)',
      zIndex: 1000,
      width: '80%', // Make the modal responsive
      maxWidth: '500px', // Set a maximum width
    },
    overlay: {
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.5)',
      zIndex: 999,
    },
    button: {
      marginTop: '1rem',
    },
    textContainer: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'flex-start',
      marginBottom: '1rem',
      wordWrap: 'break-word', // Ensure text wraps
    },
    h1: {
      textAlign: 'left', // Align h1 to the left
      width: '100%', // Ensure it takes the full width
      margin: 0, // Remove margin
    },
    h2: {
      margin: 0, // Remove margin
    },
    p: {
      margin: '0.5rem 0', // Reduce margin between p tags
      wordWrap: 'break-word', // Ensure text wraps
    },
    hr: {
      width: '100%',
      border: 'none',
      borderTop: '1px solid #ccc',
      margin: '1rem 0',
    },
    buttonContainer: {
      display: 'flex',
      justifyContent: 'space-between',
      width: '100%',
      marginTop: '1rem',
    },
  };

  return (
    <>
      <div style={styles.overlay} onClick={onClose} />
      <div style={styles.modal}>
        <h1 style={styles.h1}>Unassign Work Order</h1>
        <div style={styles.textContainer}>
          <h1 style={styles.h1}>#{workOrderNumber}</h1>
          <p>
            Unassigning this order will return all appeals back to the
            Unassigned Transcription queue.
          </p>
          <p>
            <strong>
              Please ensure that all hearing files are removed from the
              contractors's box.com folder.
            </strong>
          </p>
        </div>
        <hr style={styles.hr} />
        <div style={styles.buttonContainer}>
          <a style={styles.button} onClick={onClose}>
            Close
          </a>
          <button style={styles.button} onClick={""}>
            Unassign order
          </button>
        </div>
      </div>
    </>
  );
};

WorkOrderUnassign.propTypes = {
  onClose: PropTypes.func.isRequired,
  workOrderNumber: PropTypes.number.isRequired,
  id: PropTypes.number.isRequired,
};

export default WorkOrderUnassign;
