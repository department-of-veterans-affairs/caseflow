import React, { Fragment } from 'react';
import Alert from '../../components/Alert';
import { css } from 'glamor';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

const alertStyling = css({
  width: '57%'
});


export default class AssignStatusMessage extends React.PureComponent {


  render() {
      const alertTittle = <span>This Ro has not been assigned any hearings</span>;
      const alertMessage=<div>
        Please make sure that Ro has been assigned hearings in the current schedule</div>

      return <Alert
        title={alertMessage}
        message={alertMessage}
        type="error"
        fixed
        styling={alertStyling}
      />;
    }
  }
