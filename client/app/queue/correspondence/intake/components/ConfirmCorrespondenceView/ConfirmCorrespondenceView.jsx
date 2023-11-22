import React from 'react'
import { css } from 'glamor';
// import {useTable} from "react-table"

export const ConfirmCorrespondenceView = (props) => {

console.log(props.selectedCorrespondences.map(ting => ting.id))


  return (
    <div>
      <h1>Add Related Correspondence</h1>
      <p>Review the details below to make sure the information is correct before submitting. If you need to make changes, please go back to the associated section.</p>
      <h2>About the Correspondence</h2>
      <div {...css({ backgroundColor: '#f5f5f5', padding: '20px', marginBottom: '20px' })}>

          <div id="va-dor-header">
            <span id="va-dor-header-label" className="table-header-label">
              VA DOR
            </span>
          </div>
          <div id="va-dor-header">
            <span id="va-dor-header-label" className="table-header-label">
              VA DOR
            </span>
          </div>



        </div>
    </div>
  )
}

const mapStateToProps = (state) => ({
  correspondences: state.intakeCorrespondence.correspondences,
  unrelatedTasks: state.intakeCorrespondence.unrelatedTasks
});

