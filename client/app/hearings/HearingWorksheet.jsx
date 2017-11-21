import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Link from '../components/Link';
import Textarea from 'react-textarea-autosize';
import HearingWorksheetStream from './components/HearingWorksheetStream';
import PrintPageBreak from '../components/PrintPageBreak';
import WorksheetHeader from './components/WorksheetHeader';
import classNames from 'classnames';

// TODO Move all stream related to streams container
import HearingWorksheetDocs from './components/HearingWorksheetDocs';

import {
  onRepNameChange,
  onWitnessChange,
  onContentionsChange,
  onMilitaryServiceChange,
  onEvidenceChange,
  onCommentsForAttorneyChange
} from './actions/Dockets';

class WorksheetFormEntry extends React.PureComponent {
  render() {
    const textAreaProps = {
      minRows: 3,
      maxRows: 5000,
      ...this.props
    };

    return <div className="cf-hearings-worksheet-data">
      <label htmlFor={this.props.id}>{this.props.name}</label>
      {this.props.print ?
        <p>{this.props.value}</p> :
        <Textarea {...textAreaProps} />}
    </div>;
  }
}
export class HearingWorksheet extends React.PureComponent {
  onWitnessChange = (event) => this.props.onWitnessChange(event.target.value);
  onContentionsChange = (event) => this.props.onContentionsChange(event.target.value);
  onMilitaryServiceChange = (event) => this.props.onMilitaryServiceChange(event.target.value);
  onEvidenceChange = (event) => this.props.onEvidenceChange(event.target.value);
  onCommentsForAttorneyChange = (event) => this.props.onCommentsForAttorneyChange(event.target.value);

  render() {
    let { worksheet } = this.props;
    let readerLink = `/reader/appeal/${worksheet.appeal_vacols_id}/documents`;

    const appellant = worksheet.appellant_mi_formatted ?
      worksheet.appellant_mi_formatted : worksheet.veteran_mi_formatted;

    const worksheetHeader = <WorksheetHeader
      print={this.props.print}
      veteranLawJudge={this.props.veteran_law_judge}
      appellant={appellant}
    />;

    const firstWorksheetPage = <div>
      {worksheetHeader}
      <HearingWorksheetDocs {...this.props} />
      <HearingWorksheetStream {...this.props} print={this.props.print} />
    </div>;

    const secondWorksheetPage = <div className="cf-hearings-second-page">
      {this.props.print && worksheetHeader}

      <form className="cf-hearings-worksheet-form">
        <WorksheetFormEntry
          name="Periods and circumstances of service"
          value={worksheet.military_service}
          onChange={this.onMilitaryServiceChange}
          id="worksheet-military-service"
          minRows={1}
          print={this.props.print}
        />
        <WorksheetFormEntry
          name="Contentions"
          value={worksheet.contentions}
          onChange={this.onContentionsChange}
          id="worksheet-contentions"
          print={this.props.print}
        />
        <WorksheetFormEntry
          name="Evidence"
          value={worksheet.evidence}
          onChange={this.onEvidenceChange}
          id="worksheet-evidence"
          print={this.props.print}
        />
        <WorksheetFormEntry
          name="Comments and special instructions to attorneys"
          value={worksheet.comments_for_attorney}
          id="worksheet-comments-for-attorney"
          onChange={this.onCommentsForAttorneyChange}
          print={this.props.print}
        />
      </form>
    </div>;

    const wrapperClassNames = classNames('cf-hearings-worksheet', {
      'cf-app-segment--alt': !this.props.print
    });

    return <div>
      <div className={wrapperClassNames}>
        {firstWorksheetPage}
        <PrintPageBreak />
        {secondWorksheetPage}
      </div>
      {!this.props.print &&
      <div className="cf-push-right">
        <Link href={`${window.location.pathname}/print`} button="secondary" target="_blank">
          Save as PDF
        </Link>
        <Link
          name="review-efolder"
          href={`${readerLink}?category=case_summary`}
          button="primary"
          target="_blank">
            Review eFolder</Link>
      </div>
      }
    </div>;
  }
}

const mapStateToProps = (state) => ({
  worksheet: state.worksheet,
  worksheetAppeals: state.worksheetAppeals
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onRepNameChange,
  onWitnessChange,
  onContentionsChange,
  onMilitaryServiceChange,
  onEvidenceChange,
  onCommentsForAttorneyChange
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheet);
