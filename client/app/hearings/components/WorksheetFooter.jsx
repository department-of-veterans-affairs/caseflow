import React from 'react';
import { connect } from 'react-redux';

class WorksheetFooter extends React.PureComponent {

  render() {
    const {
      worksheet
    } = this.props;

    const veteranName = worksheet.veteran_fi_last_formatted;

    return <div>
      <div className="cf-push-right">
        {veteranName},
        <span className="cf-print-number" />
      </div>
    </div>;
  }

}

const mapStateToProps = (state) => ({
  worksheet: state.worksheet
});

export default connect(
  mapStateToProps,
  null
)(WorksheetFooter);
