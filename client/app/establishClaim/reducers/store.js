import { applyMiddleware, createStore } from 'redux';
import logger from 'redux-logger';
import establishClaimReducers from './index';
import SPECIAL_ISSUES from '../../constants/SpecialIssues';
import StringUtil from '../../util/StringUtil';
import FormField from '../../util/FormField';

let getInitialState = (props) => {

    let initialState = {
        specialIssues: {}
    };

    SPECIAL_ISSUES.forEach((issue) => {

        // Check special issue boxes based on what was sent from the database
        let snakeCaseIssueSubstring =
            StringUtil.camelCaseToSnakeCase(issue.specialIssue).substring(0, 60);

        initialState.specialIssues[issue.specialIssue] =
            props.task.appeal[snakeCaseIssueSubstring];
    });

    return initialState;
}

export const createEstablishClaimStore = (props) => {
    // Logger with default options

     return createStore(
        establishClaimReducers,
        getInitialState(props),
        applyMiddleware(logger)
    )
}