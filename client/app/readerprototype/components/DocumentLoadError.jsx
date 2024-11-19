import PropTypes from 'prop-types';
import React from 'react';
import StatusMessage from '../../components/StatusMessage';

const DocumentLoadError = ({ doc }) => {
  const downloadUrl = `${doc.content_url}?type=${doc.type}&download=true`;

  const style = {
    position: 'absolute',
    top: '40%',
    left: '50%',
    width: '816px',
    transform: 'translate(-50%, -50%)'
  };

  return (
    <div style={style}>
      <StatusMessage title="Unable to load document" type="warning">
        Caseflow is experiencing technical difficulties and cannot load <strong>{doc.type}</strong>.
        <br />
        You can try <a href={downloadUrl}>downloading the document</a> or try again later.
      </StatusMessage>
    </div>
  );
};

DocumentLoadError.propTypes = {
  doc: PropTypes.shape({
    content_url: PropTypes.string,
    type: PropTypes.string,
  }),
};

export default DocumentLoadError;
