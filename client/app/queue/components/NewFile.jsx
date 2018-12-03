// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { NewFileIcon } from '../../components/RenderFunctions';
import Tooltip from '../../components/Tooltip';
import { bindActionCreators } from 'redux';
import { getNewDocuments } from '../QueueActions';
import type { State } from '../types/state';
import COPY from '../../../COPY.json';

type Params = {|
  externalAppealId: string
|};

type Props = Params & {|
  externalId: string,
  docs: Array<Object>,
  docsLoading: ?boolean,
  error: string,
  getNewDocuments: Function
|};

class NewFile extends React.Component<Props> {
  componentDidMount = () => {
    if (!this.props.docs && !this.props.docsLoading) {
      this.props.getNewDocuments(this.props.externalId);
    }
  }

  render = () => {
    /*console.log('--INSIDE NewFile--');
    console.log(this.props.docs);*/

    if (this.props.docs && this.props.docs.length > 0) {
      return <Tooltip id="newfile-tip" text={COPY.NEW_FILE_ICON_TOOLTIP} offset={{ top: '-10px' }}>
        <NewFileIcon />
        <svg width="35px" height="11px" viewBox="0 0 40 11" xmlns="http://www.w3.org/2000/svg" version="1.1">
          <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
            <g id="Group" transform="translate(0.000000, -3.000000)">
              <g id="icon" transform="translate(0.000000, 3.000000)">
                <path d="M0.5,0.5 L0.5,10.5 L8.5,10.5 L8.5,0.5 L0.5,0.5 Z" id="Path" stroke="#844E9F"></path>
                <polygon id="Path" fill="#844E9F" points="2.25 3 2.25 4 6.75 4 6.75 3"></polygon>
                <polygon id="Path-Copy" fill="#844E9F" points="2.25 5 2.25 6 6.75 6 6.75 5"></polygon>
                <polygon id="Path-Copy-2" fill="#844E9F" points="2.25 7 2.25 8 6.75 8 6.75 7"></polygon>
              </g>
              <text id="NEW" fontFamily="SourceSansPro-Regular, Source Sans Pro" fontSize="13" fontWeight="normal" letterSpacing="-0.75" fill="#844E9F">
                <tspan x="10" y="13">N</tspan>
                <tspan x="17.661" y="13">E</tspan>
                <tspan x="24.512" y="13">W</tspan>
              </text>
            </g>
          </g>
        </svg>
      </Tooltip>;


    }

    return null;

  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const documentObject = state.queue.newDocsForAppeal[ownProps.externalAppealId];

  return {
    externalId: ownProps.externalAppealId,
    docs: documentObject ? documentObject.docs : null,
    docsLoading: documentObject ? documentObject.loading : false,
    error: documentObject ? documentObject.error : null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getNewDocuments
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(NewFile): React.ComponentType<Params>);
