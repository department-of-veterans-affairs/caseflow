import React from 'react';

// Not used yet. TODO: use it.
const AlreadyCertified = () => {
  return <div>
    <div className="usa-alert usa-alert-info cf-app-segment" role="alert">
      <div className="usa-alert-body">
        <h3 className="usa-alert-heading">
          Appeal has already been Certified
        </h3>
        <p className="usa-alert-text">
          This case has already been certified to the Board.
        </p>
      </div>
    </div>

    <div className="cf-app-segment cf-app-segment--alt">
      <h2>Appeal has already been Certified</h2>

      <p>
        This case has already been certified to the Board. If this Case is a remand
        being re-certified to the board, Caseflow is not currently able to
        process remand cases.
      </p>
    </div>
  </div>;
};

export default AlreadyCertified;
