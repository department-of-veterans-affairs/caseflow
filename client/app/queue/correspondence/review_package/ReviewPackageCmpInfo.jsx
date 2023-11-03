import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import COPY from 'app/../COPY';
import ApiUtil from 'app/util/ApiUtil';
import { sectionSegmentStyling } from 'app/queue/StickyNavContentArea';
import { TitleDetailsSubheader } from 'app/components/TitleDetailsSubheader';
import { COLORS } from 'app/constants/AppConstants';

const listItemStyling = css({
  display: 'inline-block',
  padding: '0.5rem 1.5rem 0.5rem 0',
  ':not(:last-child)': {
    '& > div': {
    },
    '& > *': {
      paddingRight: '1.5rem'
    }
  },
  '& > p': {
    fontWeight: 'bold',
    fontSize: '17px',
    marginBottom: '12px',
    marginTop: '0',
    color: '#323a45',
    lineHeight: '1.3'
  },
  '& > div': { minHeight: '22px' }
});

export const TitleDetailsSubheaderSection = ({ title, children }) => (
  <div {...listItemStyling}>
    <p>{title}</p>
    <div>
      {children}
    </div>
  </div>
);

class ReviewPackageCmpInfo extends React.PureComponent {
  constructor (props) {
    super(props);
    this.state = {
      correspondence: null,
      package_document_type: null
    };
  }

  componentDidMount (){
    const correspondence = this.props;
    
    ApiUtil.get(`/queue/correspondences/${correspondence.correspondenceId}`).then((response) => {
      this.setState({ correspondence: response.body.correspondence, package_document_type: response.body.package_document_type }); 
    });
  }

  render = () => {
    return (
      <div>
        <CmpInfoScaffolding correspondence={this.state?.correspondence} packageDocumentType = {this.state?.package_document_type} />
      </div>
    );
  };
}

const CmpInfoScaffolding = (props) => {
  const packageDocumentType = props.packageDocumentType;
  const correspondence = props.correspondence;
  const date = new Date(correspondence?.portal_entry_date);
  let customDate = date && `${date.getMonth()}/${date.getDate()}/${date.getFullYear()}`
  
  return (
    <div>
      <h2> {COPY.CORRESPONDENCE_REVIEW_CMP_INFO_TITLE} </h2>
      <TitleDetailsSubheader id="caseTitleDetailsSubheader">
        <TitleDetailsSubheaderSection title="Portal Entry Date">
          {customDate}
        </TitleDetailsSubheaderSection>
        <TitleDetailsSubheaderSection title="Source Type">
          {correspondence?.sourceType}
        </TitleDetailsSubheaderSection>
        <TitleDetailsSubheaderSection title="Package Document Type">
          {packageDocumentType?.name}
        </TitleDetailsSubheaderSection>
        <TitleDetailsSubheaderSection title="CM Packet Number">
          {correspondence?.cmpPacketNumber}
        </TitleDetailsSubheaderSection>
        <TitleDetailsSubheaderSection title="CMP Queue Name">
          {correspondence?.cmpPacketNumber}
        </TitleDetailsSubheaderSection>
        <TitleDetailsSubheaderSection title="VA DOR">
          {customDate}
        </TitleDetailsSubheaderSection>
      </TitleDetailsSubheader>
    </div>
  );
};

TitleDetailsSubheaderSection.propTypes = {
  children: PropTypes.node,
  title: PropTypes.string.isRequired
};

export default ReviewPackageCmpInfo;
