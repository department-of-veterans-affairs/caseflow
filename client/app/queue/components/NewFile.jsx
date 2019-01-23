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
  externalAppealId: string,
  cached: ?boolean
|};

type Props = Params & {|
  cached: ?boolean,
  externalId: string,
  docs: Array<Object>,
  docsLoading: ?boolean,
  error: string,
  getNewDocuments: Function
|};

class NewFile extends React.Component<Props> {
  componentDidMount = () => {
    if (!this.props.docsLoading) {
      this.props.getNewDocuments(this.props.externalId, this.props.cached);
    }
  }

  render = () => {
    if (this.props.docs && this.props.docs.length > 0) {
      return <Tooltip id="newfile-tip" text={COPY.NEW_FILE_ICON_TOOLTIP} offset={{ top: '-10px' }}>
        <NewFileIcon />
      </Tooltip>;
    }

    return null;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const documentObject = state.queue.newDocsForAppeal[ownProps.externalAppealId];

  return {
    cached: ownProps.cached,
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
