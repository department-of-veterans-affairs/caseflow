import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import COPY from 'app/../COPY';
import ApiUtil from 'app/util/ApiUtil'
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
  constructor(props){
    super(props);
    this.state = {
      correspondence: null
    }
  }

  componentDidMount(){
    const correspondence = this.props;
    ApiUtil.get(`/queue/correspondences/${correspondence.correspondenceId}`).then((response) => {
      this.setState({ correspondence: response.body.correspondence })  
    })
  }

  render = () => {
    return (
      <div>
        <CmpInfoScaffolding correspondence={this.state?.correspondence} />
      </div>
    );
  };
}

const CmpInfoScaffolding = (props) => {
  const correspondence = props.correspondence
  const date = new Date(correspondence?.portal_entry_date)
  let customDate = date && `${date.getMonth()}/${date.getDate()}/${date.getFullYear()}`
  return (
    <div>
      <h2> {COPY.CORRESPONDENCE_REVIEW_CMP_INFO_TITLE} </h2>
      <TitleDetailsSubheader id="caseTitleDetailsSubheader">
        <TitleDetailsSubheaderSection title="Portal Entry Date">
          {customDate}
        </TitleDetailsSubheaderSection>
         <TitleDetailsSubheaderSection title="Source Type">
          {correspondence?.source_type}
        </TitleDetailsSubheaderSection>
        <TitleDetailsSubheaderSection title="Package Document Type">
          {correspondence?.cmp_packet_number}
        </TitleDetailsSubheaderSection> 
        <TitleDetailsSubheaderSection title="CM Packet Number">
          {correspondence?.cmp_packet_number}
        </TitleDetailsSubheaderSection> 
        <TitleDetailsSubheaderSection title="CMP Queue Name">
          {correspondence?.cmp_packet_number}
        </TitleDetailsSubheaderSection> 
        <TitleDetailsSubheaderSection title="BVA Receipt Date">
          {customDate}
        </TitleDetailsSubheaderSection>
      </TitleDetailsSubheader>
    </div>
  )
};


TitleDetailsSubheaderSection.propTypes = {
  children: PropTypes.node,
  title: PropTypes.string.isRequired
};


export default ReviewPackageCmpInfo;
