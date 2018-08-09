// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { css } from 'glamor';
import ReactTooltip from 'react-tooltip';
import { NewFileIcon } from '../../components/RenderFunctions';
import { COLORS } from '../../constants/AppConstants';
import { bindActionCreators } from 'redux';
import { getNewDocuments } from '../QueueActions';
import type {
  BasicAppeal
} from '../types/models';

type Params = {|
  appeal: BasicAppeal
|};

type Props = Params & {|
  externalId: string,
  docs: Array<Object>,
  error: string,
  getNewDocuments: Function
|};

const tooltipID = 'newfile-tip';

const tooltipStyling = css({
  [`& > #${tooltipID}`]: {
    backgroundColor: COLORS.GREY_DARK,
    padding: '0.5rem 1rem',
    textAlign: 'center'
  },
  [`& > #${tooltipID}:after`]: { display: 'none' }
});

class NewFile extends React.Component<Props> {
  componentDidMount = () => {
    if (!this.props.docs) {
      this.props.getNewDocuments(this.props.externalId);
    }
  }

  render = () => {
    if (this.props.docs && this.props.docs.length > 0) {
      return <React.Fragment>
        <span data-tip data-for={tooltipID}>
          <NewFileIcon />
        </span>
        <span {...tooltipStyling} >
          <ReactTooltip
            effect="solid"
            id={tooltipID}
            multiline
            offset={{ top: '-10px' }} >
            This case has new <br />documents
          </ReactTooltip>
        </span>
      </React.Fragment>;
    }

    return null;

  }
}

const mapStateToProps = (state, ownProps) => {
  const externalId = ownProps.appeal.externalId || ownProps.appeal.attributes.external_id;
  const documentObject = state.queue.newDocsForAppeal[externalId];

  return {
    externalId,
    docs: documentObject ? documentObject.docs : null,
    error: documentObject ? documentObject.error : null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getNewDocuments
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(NewFile): React.ComponentType<Params>);
