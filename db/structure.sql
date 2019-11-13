SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: advance_on_docket_motions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.advance_on_docket_motions (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    granted boolean,
    person_id bigint,
    reason character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: COLUMN advance_on_docket_motions.granted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.advance_on_docket_motions.granted IS 'Whether VLJ has determined that there is sufficient cause to fast-track an appeal, i.e. grant or deny the motion to AOD.';


--
-- Name: COLUMN advance_on_docket_motions.person_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.advance_on_docket_motions.person_id IS 'Appellant ID';


--
-- Name: COLUMN advance_on_docket_motions.reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.advance_on_docket_motions.reason IS 'VLJ''s rationale for their decision on motion to AOD.';


--
-- Name: advance_on_docket_motions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.advance_on_docket_motions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: advance_on_docket_motions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.advance_on_docket_motions_id_seq OWNED BY public.advance_on_docket_motions.id;


--
-- Name: allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.allocations (
    id bigint NOT NULL,
    allocated_days double precision NOT NULL,
    created_at timestamp without time zone NOT NULL,
    regional_office character varying NOT NULL,
    schedule_period_id bigint NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: allocations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.allocations_id_seq OWNED BY public.allocations.id;


--
-- Name: annotations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.annotations (
    id integer NOT NULL,
    comment character varying NOT NULL,
    created_at timestamp without time zone,
    document_id integer NOT NULL,
    page integer,
    relevant_date date,
    updated_at timestamp without time zone,
    user_id integer,
    x integer,
    y integer
);


--
-- Name: annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.annotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.annotations_id_seq OWNED BY public.annotations.id;


--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_keys (
    id integer NOT NULL,
    consumer_name character varying NOT NULL,
    created_at timestamp without time zone,
    key_digest character varying NOT NULL,
    updated_at timestamp without time zone
);


--
-- Name: api_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_keys_id_seq OWNED BY public.api_keys.id;


--
-- Name: api_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_views (
    id integer NOT NULL,
    api_key_id integer,
    created_at timestamp without time zone,
    source character varying,
    updated_at timestamp without time zone,
    vbms_id character varying
);


--
-- Name: api_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_views_id_seq OWNED BY public.api_views.id;


--
-- Name: appeal_series; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appeal_series (
    id integer NOT NULL,
    created_at timestamp without time zone,
    incomplete boolean DEFAULT false,
    merged_appeal_count integer,
    updated_at timestamp without time zone
);


--
-- Name: appeal_series_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appeal_series_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appeal_series_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appeal_series_id_seq OWNED BY public.appeal_series.id;


--
-- Name: appeal_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appeal_views (
    id integer NOT NULL,
    appeal_id integer NOT NULL,
    appeal_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    last_viewed_at timestamp without time zone,
    updated_at timestamp without time zone NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: appeal_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appeal_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appeal_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appeal_views_id_seq OWNED BY public.appeal_views.id;


--
-- Name: appeals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appeals (
    id bigint NOT NULL,
    closest_regional_office character varying,
    created_at timestamp without time zone,
    docket_range_date date,
    docket_type character varying,
    established_at timestamp without time zone,
    establishment_attempted_at timestamp without time zone,
    establishment_canceled_at timestamp without time zone,
    establishment_error character varying,
    establishment_last_submitted_at timestamp without time zone,
    establishment_processed_at timestamp without time zone,
    establishment_submitted_at timestamp without time zone,
    legacy_opt_in_approved boolean,
    poa_participant_id character varying,
    receipt_date date,
    target_decision_date date,
    updated_at timestamp without time zone,
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    veteran_file_number character varying NOT NULL,
    veteran_is_not_claimant boolean
);


--
-- Name: TABLE appeals; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.appeals IS 'Decision reviews intaken for AMA appeals to the board (also known as a notice of disagreement).';


--
-- Name: COLUMN appeals.closest_regional_office; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.closest_regional_office IS 'The code for the regional office closest to the Veteran on the appeal.';


--
-- Name: COLUMN appeals.docket_range_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.docket_range_date IS 'Date that appeal was added to hearing docket range.';


--
-- Name: COLUMN appeals.docket_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.docket_type IS 'The docket type selected by the Veteran on their appeal form, which can be hearing, evidence submission, or direct review.';


--
-- Name: COLUMN appeals.established_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.established_at IS 'Timestamp for when the appeal has successfully been intaken into Caseflow by the user.';


--
-- Name: COLUMN appeals.establishment_attempted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.establishment_attempted_at IS 'Timestamp for when the appeal''s establishment was last attempted.';


--
-- Name: COLUMN appeals.establishment_canceled_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.establishment_canceled_at IS 'Timestamp when job was abandoned';


--
-- Name: COLUMN appeals.establishment_error; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.establishment_error IS 'The error message if attempting to establish the appeal resulted in an error. This gets cleared once the establishment is successful.';


--
-- Name: COLUMN appeals.establishment_last_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.establishment_last_submitted_at IS 'Timestamp for when the the job is eligible to run (can be reset to restart the job).';


--
-- Name: COLUMN appeals.establishment_processed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.establishment_processed_at IS 'Timestamp for when the establishment has succeeded in processing.';


--
-- Name: COLUMN appeals.establishment_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.establishment_submitted_at IS 'Timestamp for when the the intake was submitted for asynchronous processing.';


--
-- Name: COLUMN appeals.legacy_opt_in_approved; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.legacy_opt_in_approved IS 'Indicates whether a Veteran opted to withdraw matching issues from the legacy process. If there is a matching legacy issue and it is not withdrawn then it is ineligible for the decision review.';


--
-- Name: COLUMN appeals.poa_participant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.poa_participant_id IS 'Used to identify the power of attorney (POA) at the time the appeal was dispatched to BVA. Sometimes the POA changes in BGS after the fact, and BGS only returns the current representative.';


--
-- Name: COLUMN appeals.receipt_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.receipt_date IS 'Receipt date of the appeal form. Used to determine which issues are within the timeliness window to be appealed. Only issues decided prior to the receipt date will show up as contestable issues.';


--
-- Name: COLUMN appeals.target_decision_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.target_decision_date IS 'If the appeal docket is direct review, this sets the target decision date for the appeal, which is one year after the receipt date.';


--
-- Name: COLUMN appeals.uuid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.uuid IS 'The universally unique identifier for the appeal, which can be used to navigate to appeals/appeal_uuid. This allows a single ID to determine an appeal whether it is a legacy appeal or an AMA appeal.';


--
-- Name: COLUMN appeals.veteran_file_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.veteran_file_number IS 'The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran.';


--
-- Name: COLUMN appeals.veteran_is_not_claimant; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.appeals.veteran_is_not_claimant IS 'Selected by the user during intake, indicates whether the Veteran is the claimant, or if the claimant is someone else such as a dependent. Must be TRUE if Veteran is deceased.';


--
-- Name: appeals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appeals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appeals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appeals_id_seq OWNED BY public.appeals.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: attorney_case_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attorney_case_reviews (
    id integer NOT NULL,
    attorney_id integer,
    created_at timestamp without time zone NOT NULL,
    document_id character varying,
    document_type character varying,
    note text,
    overtime boolean DEFAULT false,
    reviewing_judge_id integer,
    task_id character varying,
    untimely_evidence boolean DEFAULT false,
    updated_at timestamp without time zone NOT NULL,
    work_product character varying
);


--
-- Name: attorney_case_reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attorney_case_reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attorney_case_reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attorney_case_reviews_id_seq OWNED BY public.attorney_case_reviews.id;


--
-- Name: available_hearing_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.available_hearing_locations (
    id bigint NOT NULL,
    address character varying,
    appeal_id integer,
    appeal_type character varying,
    city character varying,
    classification character varying,
    created_at timestamp without time zone NOT NULL,
    distance double precision,
    facility_id character varying,
    facility_type character varying,
    name character varying,
    state character varying,
    updated_at timestamp without time zone NOT NULL,
    veteran_file_number character varying,
    zip_code character varying
);


--
-- Name: available_hearing_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.available_hearing_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: available_hearing_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.available_hearing_locations_id_seq OWNED BY public.available_hearing_locations.id;


--
-- Name: board_grant_effectuations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.board_grant_effectuations (
    id bigint NOT NULL,
    appeal_id bigint NOT NULL,
    contention_reference_id character varying,
    created_at timestamp without time zone,
    decision_document_id bigint,
    decision_sync_attempted_at timestamp without time zone,
    decision_sync_canceled_at timestamp without time zone,
    decision_sync_error character varying,
    decision_sync_last_submitted_at timestamp without time zone,
    decision_sync_processed_at timestamp without time zone,
    decision_sync_submitted_at timestamp without time zone,
    end_product_establishment_id bigint,
    granted_decision_issue_id bigint NOT NULL,
    last_submitted_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: TABLE board_grant_effectuations; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.board_grant_effectuations IS 'Represents the work item of updating records in response to a granted issue on a Board appeal. Some are represented as contentions on an EP in VBMS. Others are tracked via Caseflow tasks.';


--
-- Name: COLUMN board_grant_effectuations.appeal_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.appeal_id IS 'The ID of the appeal containing the granted issue being effectuated.';


--
-- Name: COLUMN board_grant_effectuations.contention_reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.contention_reference_id IS 'The ID of the contention created in VBMS. Indicates successful creation of the contention. If the EP has been rated, this contention could have been connected to a rating issue. That connection is used to map the rating issue back to the decision issue.';


--
-- Name: COLUMN board_grant_effectuations.decision_document_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.decision_document_id IS 'The ID of the decision document which triggered this effectuation.';


--
-- Name: COLUMN board_grant_effectuations.decision_sync_attempted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.decision_sync_attempted_at IS 'When the EP is cleared, an asyncronous job attempts to map the resulting rating issue back to the decision issue. Timestamp representing the time the job was last attempted.';


--
-- Name: COLUMN board_grant_effectuations.decision_sync_canceled_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.decision_sync_canceled_at IS 'Timestamp when job was abandoned';


--
-- Name: COLUMN board_grant_effectuations.decision_sync_error; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.decision_sync_error IS 'Async job processing last error message. See description for decision_sync_attempted_at for the decision sync job description.';


--
-- Name: COLUMN board_grant_effectuations.decision_sync_last_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.decision_sync_last_submitted_at IS 'Timestamp for when the the job is eligible to run (can be reset to restart the job).';


--
-- Name: COLUMN board_grant_effectuations.decision_sync_processed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.decision_sync_processed_at IS 'Async job processing completed timestamp. See description for decision_sync_attempted_at for the decision sync job description.';


--
-- Name: COLUMN board_grant_effectuations.decision_sync_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.decision_sync_submitted_at IS 'Async job processing start timestamp. See description for decision_sync_attempted_at for the decision sync job description.';


--
-- Name: COLUMN board_grant_effectuations.end_product_establishment_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.end_product_establishment_id IS 'The ID of the end product establishment created for this board grant effectuation.';


--
-- Name: COLUMN board_grant_effectuations.granted_decision_issue_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.granted_decision_issue_id IS 'The ID of the granted decision issue.';


--
-- Name: COLUMN board_grant_effectuations.last_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.board_grant_effectuations.last_submitted_at IS 'Async job processing most recent start timestamp (TODO rename)';


--
-- Name: board_grant_effectuations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.board_grant_effectuations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: board_grant_effectuations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.board_grant_effectuations_id_seq OWNED BY public.board_grant_effectuations.id;


--
-- Name: cached_appeal_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cached_appeal_attributes (
    appeal_id integer,
    appeal_type character varying,
    assignee_label character varying,
    case_type character varying,
    closest_regional_office_city character varying,
    closest_regional_office_key character varying,
    created_at timestamp without time zone,
    docket_number character varying,
    docket_type character varying,
    is_aod boolean,
    issue_count integer,
    updated_at timestamp without time zone,
    vacols_id character varying,
    veteran_name character varying
);


--
-- Name: COLUMN cached_appeal_attributes.assignee_label; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cached_appeal_attributes.assignee_label IS 'Who is currently most responsible for the appeal';


--
-- Name: COLUMN cached_appeal_attributes.case_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cached_appeal_attributes.case_type IS 'The case type, i.e. original, post remand, CAVC remand, etc';


--
-- Name: COLUMN cached_appeal_attributes.closest_regional_office_city; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cached_appeal_attributes.closest_regional_office_city IS 'Closest regional office to the veteran';


--
-- Name: COLUMN cached_appeal_attributes.closest_regional_office_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cached_appeal_attributes.closest_regional_office_key IS 'Closest regional office to the veteran in 4 character key';


--
-- Name: COLUMN cached_appeal_attributes.is_aod; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cached_appeal_attributes.is_aod IS 'Whether the case is Advanced on Docket';


--
-- Name: COLUMN cached_appeal_attributes.issue_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cached_appeal_attributes.issue_count IS 'Number of issues on the appeal.';


--
-- Name: COLUMN cached_appeal_attributes.veteran_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cached_appeal_attributes.veteran_name IS '''LastName, FirstName'' of the veteran';


--
-- Name: cached_user_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cached_user_attributes (
    created_at timestamp without time zone NOT NULL,
    sactive character varying NOT NULL,
    sattyid character varying,
    sdomainid character varying NOT NULL,
    slogid character varying NOT NULL,
    stafkey character varying NOT NULL,
    svlj character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE cached_user_attributes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.cached_user_attributes IS 'VACOLS cached staff table attributes';


--
-- Name: certification_cancellations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.certification_cancellations (
    id integer NOT NULL,
    cancellation_reason character varying,
    certification_id integer,
    created_at timestamp without time zone,
    email character varying,
    other_reason character varying,
    updated_at timestamp without time zone
);


--
-- Name: certification_cancellations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.certification_cancellations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: certification_cancellations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.certification_cancellations_id_seq OWNED BY public.certification_cancellations.id;


--
-- Name: certifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.certifications (
    id integer NOT NULL,
    already_certified boolean,
    bgs_rep_address_line_1 character varying,
    bgs_rep_address_line_2 character varying,
    bgs_rep_address_line_3 character varying,
    bgs_rep_city character varying,
    bgs_rep_country character varying,
    bgs_rep_state character varying,
    bgs_rep_zip character varying,
    bgs_representative_name character varying,
    bgs_representative_type character varying,
    certification_date character varying,
    certifying_office character varying,
    certifying_official_name character varying,
    certifying_official_title character varying,
    certifying_username character varying,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    form8_started_at timestamp without time zone,
    form9_matching_at timestamp without time zone,
    form9_type character varying,
    hearing_change_doc_found_in_vbms boolean,
    hearing_preference character varying,
    loading_data boolean,
    loading_data_failed boolean,
    nod_matching_at timestamp without time zone,
    poa_correct_in_bgs boolean,
    poa_correct_in_vacols boolean,
    poa_matches boolean,
    representative_name character varying,
    representative_type character varying,
    soc_matching_at timestamp without time zone,
    ssocs_matching_at timestamp without time zone,
    ssocs_required boolean,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    v2 boolean,
    vacols_data_missing boolean,
    vacols_hearing_preference character varying,
    vacols_id character varying,
    vacols_representative_name character varying,
    vacols_representative_type character varying
);


--
-- Name: certifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.certifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: certifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.certifications_id_seq OWNED BY public.certifications.id;


--
-- Name: claim_establishments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claim_establishments (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    decision_type integer,
    email_recipient character varying,
    email_ro_id character varying,
    ep_code character varying,
    outcoding_date timestamp without time zone,
    task_id integer,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: claim_establishments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claim_establishments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claim_establishments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claim_establishments_id_seq OWNED BY public.claim_establishments.id;


--
-- Name: claimants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claimants (
    id bigint NOT NULL,
    created_at timestamp without time zone,
    decision_review_id bigint,
    decision_review_type character varying,
    participant_id character varying NOT NULL,
    payee_code character varying,
    updated_at timestamp without time zone
);


--
-- Name: TABLE claimants; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.claimants IS 'This table bridges decision reviews to participants when the participant is listed as a claimant on the decision review. A participant can be a claimant on multiple decision reviews.';


--
-- Name: COLUMN claimants.decision_review_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claimants.decision_review_id IS 'The ID of the decision review the claimant is on.';


--
-- Name: COLUMN claimants.decision_review_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claimants.decision_review_type IS 'The type of decision review the claimant is on.';


--
-- Name: COLUMN claimants.participant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claimants.participant_id IS 'The participant ID of the claimant.';


--
-- Name: COLUMN claimants.payee_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claimants.payee_code IS 'The payee_code for the claimant, if applicable. payee_code is required when the claim is processed in VBMS.';


--
-- Name: claimants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claimants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claimants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claimants_id_seq OWNED BY public.claimants.id;


--
-- Name: claims_folder_searches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_folder_searches (
    id integer NOT NULL,
    appeal_id integer,
    appeal_type character varying NOT NULL,
    created_at timestamp without time zone,
    query character varying,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: claims_folder_searches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_folder_searches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_folder_searches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_folder_searches_id_seq OWNED BY public.claims_folder_searches.id;


--
-- Name: decision_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.decision_documents (
    id bigint NOT NULL,
    appeal_id bigint NOT NULL,
    appeal_type character varying,
    attempted_at timestamp without time zone,
    canceled_at timestamp without time zone,
    citation_number character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    decision_date date NOT NULL,
    error character varying,
    last_submitted_at timestamp without time zone,
    processed_at timestamp without time zone,
    redacted_document_location character varying NOT NULL,
    submitted_at timestamp without time zone,
    updated_at timestamp without time zone NOT NULL,
    uploaded_to_vbms_at timestamp without time zone
);


--
-- Name: COLUMN decision_documents.canceled_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_documents.canceled_at IS 'Timestamp when job was abandoned';


--
-- Name: decision_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.decision_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: decision_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.decision_documents_id_seq OWNED BY public.decision_documents.id;


--
-- Name: decision_issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.decision_issues (
    id bigint NOT NULL,
    benefit_type character varying,
    caseflow_decision_date date,
    created_at timestamp without time zone,
    decision_review_id integer,
    decision_review_type character varying,
    decision_text character varying,
    deleted_at timestamp without time zone,
    description character varying,
    diagnostic_code character varying,
    disposition character varying,
    end_product_last_action_date date,
    participant_id character varying NOT NULL,
    rating_issue_reference_id character varying,
    rating_profile_date timestamp without time zone,
    rating_promulgation_date timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: TABLE decision_issues; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.decision_issues IS 'Issues that represent a decision made on a decision review.';


--
-- Name: COLUMN decision_issues.benefit_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.benefit_type IS 'Classification of the benefit being decided on. Maps 1 to 1 to VA lines of business, and typically used to know which line of business the decision correlates to.';


--
-- Name: COLUMN decision_issues.caseflow_decision_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.caseflow_decision_date IS 'This is a decision date for decision issues where decisions are entered in Caseflow, such as for appeals or for decision reviews with a business line that is not processed in VBMS.';


--
-- Name: COLUMN decision_issues.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.created_at IS 'Automatic timestamp when row was created.';


--
-- Name: COLUMN decision_issues.decision_review_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.decision_review_id IS 'ID of the decision review the decision was made on.';


--
-- Name: COLUMN decision_issues.decision_review_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.decision_review_type IS 'Type of the decision review the decision was made on.';


--
-- Name: COLUMN decision_issues.decision_text; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.decision_text IS 'If decision resulted in a change to a rating, the rating issue''s decision text.';


--
-- Name: COLUMN decision_issues.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.description IS 'Optional description that the user can input for decisions made in Caseflow.';


--
-- Name: COLUMN decision_issues.diagnostic_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.diagnostic_code IS 'If a decision resulted in a rating, this is the rating issue''s diagnostic code.';


--
-- Name: COLUMN decision_issues.disposition; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.disposition IS 'The disposition for a decision issue. Dispositions made in Caseflow and dispositions made in VBMS can have different values.';


--
-- Name: COLUMN decision_issues.end_product_last_action_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.end_product_last_action_date IS 'After an end product gets synced with a status of CLR (cleared), the end product''s last_action_date is saved on any decision issues that are created as a result. This is used as a proxy for decision date for non-rating issues that are processed in VBMS because they don''t have a rating profile date, and the exact decision date is not available.';


--
-- Name: COLUMN decision_issues.participant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.participant_id IS 'The Veteran''s participant id.';


--
-- Name: COLUMN decision_issues.rating_issue_reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.rating_issue_reference_id IS 'Identifies the specific issue on the rating that resulted from the decision issue (a rating can have multiple issues). This is unique per rating issue.';


--
-- Name: COLUMN decision_issues.rating_profile_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.rating_profile_date IS 'The profile date of the rating that a decision issue resulted in (if applicable). The profile_date is used as an identifier for the rating, and is the date that most closely maps to what the Veteran writes down as the decision date.';


--
-- Name: COLUMN decision_issues.rating_promulgation_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.decision_issues.rating_promulgation_date IS 'The promulgation date of the rating that a decision issue resulted in (if applicable). It is used for calculating whether a decision issue is within the timeliness window to be appealed or get a higher level review.';


--
-- Name: decision_issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.decision_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: decision_issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.decision_issues_id_seq OWNED BY public.decision_issues.id;


--
-- Name: dispatch_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dispatch_tasks (
    id integer NOT NULL,
    aasm_state character varying,
    appeal_id integer NOT NULL,
    assigned_at timestamp without time zone,
    comment character varying,
    completed_at timestamp without time zone,
    completion_status integer,
    created_at timestamp without time zone NOT NULL,
    lock_version integer,
    outgoing_reference_id character varying,
    prepared_at timestamp without time zone,
    started_at timestamp without time zone,
    type character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer
);


--
-- Name: dispatch_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dispatch_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dispatch_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dispatch_tasks_id_seq OWNED BY public.dispatch_tasks.id;


--
-- Name: distributed_cases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.distributed_cases (
    id bigint NOT NULL,
    case_id character varying,
    created_at timestamp without time zone,
    distribution_id integer,
    docket character varying,
    docket_index integer,
    genpop boolean,
    genpop_query character varying,
    priority boolean,
    ready_at timestamp without time zone,
    task_id integer,
    updated_at timestamp without time zone
);


--
-- Name: distributed_cases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.distributed_cases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: distributed_cases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.distributed_cases_id_seq OWNED BY public.distributed_cases.id;


--
-- Name: distributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.distributions (
    id bigint NOT NULL,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    errored_at timestamp without time zone,
    judge_id integer,
    started_at timestamp without time zone,
    statistics json,
    status character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: COLUMN distributions.errored_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.distributions.errored_at IS 'when the Distribution job suffered an error';


--
-- Name: COLUMN distributions.started_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.distributions.started_at IS 'when the Distribution job commenced';


--
-- Name: distributions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.distributions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: distributions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.distributions_id_seq OWNED BY public.distributions.id;


--
-- Name: docket_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.docket_snapshots (
    id integer NOT NULL,
    created_at timestamp without time zone,
    docket_count integer,
    latest_docket_month date,
    updated_at timestamp without time zone
);


--
-- Name: docket_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.docket_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: docket_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.docket_snapshots_id_seq OWNED BY public.docket_snapshots.id;


--
-- Name: docket_tracers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.docket_tracers (
    id integer NOT NULL,
    ahead_and_ready_count integer,
    ahead_count integer,
    created_at timestamp without time zone,
    docket_snapshot_id integer,
    month date,
    updated_at timestamp without time zone
);


--
-- Name: docket_tracers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.docket_tracers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: docket_tracers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.docket_tracers_id_seq OWNED BY public.docket_tracers.id;


--
-- Name: document_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_views (
    id integer NOT NULL,
    created_at timestamp without time zone,
    document_id integer NOT NULL,
    first_viewed_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer NOT NULL
);


--
-- Name: document_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.document_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: document_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.document_views_id_seq OWNED BY public.document_views.id;


--
-- Name: documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documents (
    id integer NOT NULL,
    category_medical boolean,
    category_other boolean,
    category_procedural boolean,
    created_at timestamp without time zone,
    description character varying,
    file_number character varying,
    previous_document_version_id integer,
    received_at date,
    series_id character varying,
    type character varying,
    updated_at timestamp without time zone,
    upload_date date,
    vbms_document_id character varying NOT NULL
);


--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documents_id_seq OWNED BY public.documents.id;


--
-- Name: documents_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documents_tags (
    id integer NOT NULL,
    created_at timestamp without time zone,
    document_id integer NOT NULL,
    tag_id integer NOT NULL,
    updated_at timestamp without time zone
);


--
-- Name: documents_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documents_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documents_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documents_tags_id_seq OWNED BY public.documents_tags.id;


--
-- Name: end_product_code_updates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.end_product_code_updates (
    id bigint NOT NULL,
    code character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    end_product_establishment_id bigint NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE end_product_code_updates; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.end_product_code_updates IS 'Caseflow establishes end products in VBMS with specific end product codes. If that code is changed outside of Caseflow, that is tracked here.';


--
-- Name: COLUMN end_product_code_updates.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_code_updates.code IS 'The new end product code, if it has changed since last checked.';


--
-- Name: end_product_code_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.end_product_code_updates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: end_product_code_updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.end_product_code_updates_id_seq OWNED BY public.end_product_code_updates.id;


--
-- Name: end_product_establishments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.end_product_establishments (
    id bigint NOT NULL,
    benefit_type_code character varying,
    claim_date date,
    claimant_participant_id character varying,
    code character varying,
    committed_at timestamp without time zone,
    created_at timestamp without time zone,
    development_item_reference_id character varying,
    doc_reference_id character varying,
    established_at timestamp without time zone,
    last_synced_at timestamp without time zone,
    limited_poa_access boolean,
    limited_poa_code character varying,
    modifier character varying,
    payee_code character varying NOT NULL,
    reference_id character varying,
    source_id bigint NOT NULL,
    source_type character varying NOT NULL,
    station character varying,
    synced_status character varying,
    updated_at timestamp without time zone,
    user_id integer,
    veteran_file_number character varying NOT NULL
);


--
-- Name: TABLE end_product_establishments; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.end_product_establishments IS 'Represents end products that have been, or need to be established by Caseflow. Used to track the status of those end products as they are processed in VBMS and/or SHARE.';


--
-- Name: COLUMN end_product_establishments.benefit_type_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.benefit_type_code IS '1 if the Veteran is alive, and 2 if the Veteran is deceased. Not to be confused with benefit_type, which is unrelated.';


--
-- Name: COLUMN end_product_establishments.claim_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.claim_date IS 'The claim_date for end product established.';


--
-- Name: COLUMN end_product_establishments.claimant_participant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.claimant_participant_id IS 'The participant ID of the claimant submitted on the end product.';


--
-- Name: COLUMN end_product_establishments.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.code IS 'The end product code, which determines the type of end product that is established. For example, it can contain information about whether it is rating, nonrating, compensation, pension, created automatically due to a Duty to Assist Error, and more.';


--
-- Name: COLUMN end_product_establishments.committed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.committed_at IS 'Timestamp indicating other actions performed as part of a larger atomic operation containing the end product establishment, such as creating contentions, are also complete.';


--
-- Name: COLUMN end_product_establishments.development_item_reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.development_item_reference_id IS 'When a Veteran requests an informal conference with their higher level review, a tracked item is created. This stores the ID of the of the tracked item, it is also used to indicate the success of creating the tracked item.';


--
-- Name: COLUMN end_product_establishments.doc_reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.doc_reference_id IS 'When a Veteran requests an informal conference, a claimant letter is generated. This stores the document ID of the claimant letter, and is also used to track the success of creating the claimant letter.';


--
-- Name: COLUMN end_product_establishments.established_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.established_at IS 'Timestamp for when the end product was established.';


--
-- Name: COLUMN end_product_establishments.last_synced_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.last_synced_at IS 'The time that the status of the end product was last synced with BGS. The end product is synced until it is canceled or cleared, meaning it is no longer active.';


--
-- Name: COLUMN end_product_establishments.limited_poa_access; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.limited_poa_access IS 'Indicates whether the limited Power of Attorney has access to view documents';


--
-- Name: COLUMN end_product_establishments.limited_poa_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.limited_poa_code IS 'The limited Power of Attorney code, which indicates whether the claim has a POA specifically for this claim, which can be different than the Veteran''s POA';


--
-- Name: COLUMN end_product_establishments.modifier; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.modifier IS 'The end product modifier. For higher level reviews, the modifiers range from 030-039. For supplemental claims, they range from 040-049. The same modifier cannot be used twice for an active end product per Veteran. Once an end product is no longer active, the modifier can be used again.';


--
-- Name: COLUMN end_product_establishments.payee_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.payee_code IS 'The payee_code of the claimant submitted for this end product.';


--
-- Name: COLUMN end_product_establishments.reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.reference_id IS 'The claim_id of the end product, which is stored after the end product is successfully established in VBMS.';


--
-- Name: COLUMN end_product_establishments.source_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.source_id IS 'The ID of the source that resulted in this end product establishment.';


--
-- Name: COLUMN end_product_establishments.source_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.source_type IS 'The type of source that resulted in this end product establishment.';


--
-- Name: COLUMN end_product_establishments.station; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.station IS 'The station ID of the end product''s station.';


--
-- Name: COLUMN end_product_establishments.synced_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.synced_status IS 'The status of the end product, which is synced by a job. Once and end product is cleared (CLR) or canceled (CAN) the status is final and the end product will not continue being synced.';


--
-- Name: COLUMN end_product_establishments.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.user_id IS 'The ID of the user who performed the decision review intake.';


--
-- Name: COLUMN end_product_establishments.veteran_file_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.end_product_establishments.veteran_file_number IS 'The file number of the Veteran submitted when establishing the end product.';


--
-- Name: end_product_establishments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.end_product_establishments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: end_product_establishments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.end_product_establishments_id_seq OWNED BY public.end_product_establishments.id;


--
-- Name: form8s; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.form8s (
    id integer NOT NULL,
    _initial_appellant_name character varying,
    _initial_appellant_relationship character varying,
    _initial_hearing_requested character varying,
    _initial_increased_rating_notification_date date,
    _initial_insurance_loan_number character varying,
    _initial_other_notification_date date,
    _initial_representative_name character varying,
    _initial_representative_type character varying,
    _initial_service_connection_notification_date date,
    _initial_soc_date date,
    _initial_ssoc_required character varying,
    _initial_veteran_name character varying,
    agent_accredited character varying,
    appellant_name character varying,
    appellant_relationship character varying,
    certification_date date,
    certification_id integer,
    certifying_office character varying,
    certifying_official_name character varying,
    certifying_official_title character varying,
    certifying_official_title_specify_other character varying,
    certifying_username character varying,
    contested_claims_procedures_applicable character varying,
    contested_claims_requirements_followed character varying,
    created_at timestamp without time zone NOT NULL,
    file_number character varying,
    form9_date date,
    form_646_not_of_record_explanation character varying,
    form_646_of_record character varying,
    hearing_held character varying,
    hearing_preference character varying,
    hearing_requested character varying,
    hearing_requested_explanation character varying,
    hearing_transcript_on_file character varying,
    increased_rating_for text,
    increased_rating_notification_date date,
    insurance_loan_number character varying,
    nod_date date,
    other_for text,
    other_notification_date date,
    power_of_attorney character varying,
    power_of_attorney_file character varying,
    record_cf_or_xcf character varying,
    record_clinical_rec character varying,
    record_dental_f character varying,
    record_dep_ed_f character varying,
    record_hospital_cor character varying,
    record_inactive_cf character varying,
    record_insurance_f character varying,
    record_loan_guar_f character varying,
    record_other character varying,
    record_other_explanation text,
    record_outpatient_f character varying,
    record_r_and_e_f character varying,
    record_slides character varying,
    record_tissue_blocks character varying,
    record_training_sub_f character varying,
    record_x_rays character varying,
    remarks text,
    representative_name character varying,
    representative_type character varying,
    representative_type_specify_other character varying,
    service_connection_for text,
    service_connection_notification_date date,
    soc_date date,
    ssoc_date_1 date,
    ssoc_date_2 date,
    ssoc_date_3 date,
    ssoc_required character varying,
    updated_at timestamp without time zone NOT NULL,
    vacols_id character varying,
    veteran_name character varying
);


--
-- Name: form8s_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.form8s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: form8s_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.form8s_id_seq OWNED BY public.form8s.id;


--
-- Name: global_admin_logins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.global_admin_logins (
    id integer NOT NULL,
    admin_css_id character varying,
    created_at timestamp without time zone,
    target_css_id character varying,
    target_station_id character varying,
    updated_at timestamp without time zone
);


--
-- Name: global_admin_logins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.global_admin_logins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: global_admin_logins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.global_admin_logins_id_seq OWNED BY public.global_admin_logins.id;


--
-- Name: hearing_appeal_stream_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hearing_appeal_stream_snapshots (
    appeal_id integer,
    created_at timestamp without time zone NOT NULL,
    hearing_id integer,
    updated_at timestamp without time zone
);


--
-- Name: hearing_days; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hearing_days (
    id bigint NOT NULL,
    bva_poc character varying,
    created_at timestamp without time zone NOT NULL,
    created_by_id bigint NOT NULL,
    deleted_at timestamp without time zone,
    judge_id integer,
    lock boolean,
    notes text,
    regional_office character varying,
    request_type character varying NOT NULL,
    room character varying,
    scheduled_for date NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by_id bigint NOT NULL
);


--
-- Name: COLUMN hearing_days.created_by_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hearing_days.created_by_id IS 'The ID of the user who created the Hearing Day';


--
-- Name: COLUMN hearing_days.room; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hearing_days.room IS 'The room at BVA where the hearing will take place';


--
-- Name: COLUMN hearing_days.updated_by_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hearing_days.updated_by_id IS 'The ID of the user who most recently updated the Hearing Day';


--
-- Name: hearing_days_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hearing_days_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hearing_days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hearing_days_id_seq OWNED BY public.hearing_days.id;


--
-- Name: hearing_issue_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hearing_issue_notes (
    id bigint NOT NULL,
    allow boolean DEFAULT false,
    created_at timestamp without time zone,
    deny boolean DEFAULT false,
    dismiss boolean DEFAULT false,
    hearing_id bigint NOT NULL,
    remand boolean DEFAULT false,
    reopen boolean DEFAULT false,
    request_issue_id bigint NOT NULL,
    updated_at timestamp without time zone,
    worksheet_notes character varying
);


--
-- Name: hearing_issue_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hearing_issue_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hearing_issue_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hearing_issue_notes_id_seq OWNED BY public.hearing_issue_notes.id;


--
-- Name: hearing_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hearing_locations (
    id bigint NOT NULL,
    address character varying,
    city character varying,
    classification character varying,
    created_at timestamp without time zone NOT NULL,
    distance double precision,
    facility_id character varying,
    facility_type character varying,
    hearing_id integer,
    hearing_type character varying,
    name character varying,
    state character varying,
    updated_at timestamp without time zone NOT NULL,
    zip_code character varying
);


--
-- Name: hearing_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hearing_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hearing_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hearing_locations_id_seq OWNED BY public.hearing_locations.id;


--
-- Name: hearing_task_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hearing_task_associations (
    id bigint NOT NULL,
    created_at timestamp without time zone,
    hearing_id bigint NOT NULL,
    hearing_task_id bigint NOT NULL,
    hearing_type character varying NOT NULL,
    updated_at timestamp without time zone
);


--
-- Name: hearing_task_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hearing_task_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hearing_task_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hearing_task_associations_id_seq OWNED BY public.hearing_task_associations.id;


--
-- Name: hearing_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hearing_views (
    id integer NOT NULL,
    created_at timestamp without time zone,
    hearing_id integer NOT NULL,
    hearing_type character varying,
    updated_at timestamp without time zone,
    user_id integer NOT NULL
);


--
-- Name: hearing_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hearing_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hearing_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hearing_views_id_seq OWNED BY public.hearing_views.id;


--
-- Name: hearings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hearings (
    id bigint NOT NULL,
    appeal_id integer NOT NULL,
    bva_poc character varying,
    created_at timestamp without time zone,
    created_by_id bigint,
    disposition character varying,
    evidence_window_waived boolean,
    hearing_day_id integer NOT NULL,
    judge_id integer,
    military_service character varying,
    notes character varying,
    prepped boolean,
    representative_name character varying,
    room character varying,
    scheduled_time time without time zone NOT NULL,
    summary text,
    transcript_requested boolean,
    transcript_sent_date date,
    updated_at timestamp without time zone,
    updated_by_id bigint,
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    witness character varying
);


--
-- Name: COLUMN hearings.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hearings.created_at IS 'Automatic timestamp when row was created.';


--
-- Name: COLUMN hearings.created_by_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hearings.created_by_id IS 'The ID of the user who created the Hearing';


--
-- Name: COLUMN hearings.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hearings.updated_at IS 'Timestamp when record was last updated.';


--
-- Name: COLUMN hearings.updated_by_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hearings.updated_by_id IS 'The ID of the user who most recently updated the Hearing';


--
-- Name: hearings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hearings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hearings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hearings_id_seq OWNED BY public.hearings.id;


--
-- Name: higher_level_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.higher_level_reviews (
    id bigint NOT NULL,
    benefit_type character varying,
    created_at timestamp without time zone,
    establishment_attempted_at timestamp without time zone,
    establishment_canceled_at timestamp without time zone,
    establishment_error character varying,
    establishment_last_submitted_at timestamp without time zone,
    establishment_processed_at timestamp without time zone,
    establishment_submitted_at timestamp without time zone,
    informal_conference boolean,
    legacy_opt_in_approved boolean,
    receipt_date date,
    same_office boolean,
    updated_at timestamp without time zone,
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    veteran_file_number character varying NOT NULL,
    veteran_is_not_claimant boolean
);


--
-- Name: TABLE higher_level_reviews; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.higher_level_reviews IS 'Intake data for Higher Level Reviews.';


--
-- Name: COLUMN higher_level_reviews.benefit_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.benefit_type IS 'The benefit type selected by the Veteran on their form, also known as a Line of Business.';


--
-- Name: COLUMN higher_level_reviews.establishment_attempted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.establishment_attempted_at IS 'Timestamp for the most recent attempt at establishing a claim.';


--
-- Name: COLUMN higher_level_reviews.establishment_canceled_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.establishment_canceled_at IS 'Timestamp when job was abandoned';


--
-- Name: COLUMN higher_level_reviews.establishment_error; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.establishment_error IS 'The error captured for the most recent attempt at establishing a claim if it failed.  This is removed once establishing the claim succeeds.';


--
-- Name: COLUMN higher_level_reviews.establishment_last_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.establishment_last_submitted_at IS 'Timestamp for the latest attempt at establishing the End Products for the Decision Review.';


--
-- Name: COLUMN higher_level_reviews.establishment_processed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.establishment_processed_at IS 'Timestamp for when the End Product Establishments for the Decision Review successfully finished processing.';


--
-- Name: COLUMN higher_level_reviews.establishment_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.establishment_submitted_at IS 'Timestamp for when the Higher Level Review was submitted by a Claims Assistant. This adds the End Product Establishment to a job to finish processing asynchronously.';


--
-- Name: COLUMN higher_level_reviews.informal_conference; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.informal_conference IS 'Indicates whether a Veteran selected on their Higher Level Review form to have an informal conference. This creates a claimant letter and a tracked item in BGS.';


--
-- Name: COLUMN higher_level_reviews.legacy_opt_in_approved; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.legacy_opt_in_approved IS 'Indicates whether a Veteran opted to withdraw their Higher Level Review request issues from the legacy system if a matching issue is found. If there is a matching legacy issue and it is not withdrawn, then that issue is ineligible to be a new request issue and a contention will not be created for it.';


--
-- Name: COLUMN higher_level_reviews.receipt_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.receipt_date IS 'The date that the Higher Level Review form was received by central mail. This is used to determine which issues are eligible to be appealed based on timeliness.  Only issues decided prior to the receipt date will show up as contestable issues.  It is also the claim date for any associated end products that are established.';


--
-- Name: COLUMN higher_level_reviews.same_office; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.same_office IS 'Whether the Veteran wants their issues to be reviewed by the same office where they were previously reviewed. This creates a special issue on all of the contentions created on this Higher Level Review.';


--
-- Name: COLUMN higher_level_reviews.uuid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.uuid IS 'The universally unique identifier for the Higher Level Review. Can be used to link to the claim after it is completed.';


--
-- Name: COLUMN higher_level_reviews.veteran_file_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.veteran_file_number IS 'The file number of the Veteran that the Higher Level Review is for.';


--
-- Name: COLUMN higher_level_reviews.veteran_is_not_claimant; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.higher_level_reviews.veteran_is_not_claimant IS 'Indicates whether the Veteran is the claimant on the Higher Level Review form, or if the claimant is someone else like a spouse or a child. Must be TRUE if the Veteran is deceased.';


--
-- Name: higher_level_reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.higher_level_reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: higher_level_reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.higher_level_reviews_id_seq OWNED BY public.higher_level_reviews.id;


--
-- Name: intakes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intakes (
    id integer NOT NULL,
    cancel_other character varying,
    cancel_reason character varying,
    completed_at timestamp without time zone,
    completion_started_at timestamp without time zone,
    completion_status character varying,
    created_at timestamp without time zone,
    detail_id integer,
    detail_type character varying,
    error_code character varying,
    started_at timestamp without time zone,
    type character varying,
    updated_at timestamp without time zone,
    user_id integer NOT NULL,
    veteran_file_number character varying
);


--
-- Name: TABLE intakes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.intakes IS 'Represents the intake of an form or request made by a veteran.';


--
-- Name: COLUMN intakes.cancel_other; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.cancel_other IS 'Notes added if a user canceled an intake for any reason other than the stock set of options.';


--
-- Name: COLUMN intakes.cancel_reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.cancel_reason IS 'The reason the intake was canceled. Could have been manually canceled by a user, or automatic.';


--
-- Name: COLUMN intakes.completed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.completed_at IS 'Timestamp for when the intake was completed, whether it was successful or not.';


--
-- Name: COLUMN intakes.completion_started_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.completion_started_at IS 'Timestamp for when the user submitted the intake to be completed.';


--
-- Name: COLUMN intakes.completion_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.completion_status IS 'Indicates whether the intake was successful, or was closed by being canceled, expired, or due to an error.';


--
-- Name: COLUMN intakes.detail_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.detail_id IS 'The ID of the record created as a result of the intake.';


--
-- Name: COLUMN intakes.detail_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.detail_type IS 'The type of the record created as a result of the intake.';


--
-- Name: COLUMN intakes.error_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.error_code IS 'If the intake was unsuccessful due to a set of known errors, the error code is stored here. An error is also stored here for RAMP elections that are connected to an active end product, even though the intake is a success.';


--
-- Name: COLUMN intakes.started_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.started_at IS 'Timestamp for when the intake was created, which happens when a user successfully searches for a Veteran.';


--
-- Name: COLUMN intakes.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.type IS 'The class name of the intake.';


--
-- Name: COLUMN intakes.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.user_id IS 'The ID of the user who created the intake.';


--
-- Name: COLUMN intakes.veteran_file_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intakes.veteran_file_number IS 'The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran.';


--
-- Name: intakes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intakes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intakes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intakes_id_seq OWNED BY public.intakes.id;


--
-- Name: job_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_notes (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    job_id bigint NOT NULL,
    job_type character varying NOT NULL,
    note text NOT NULL,
    send_to_intake_user boolean DEFAULT false,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: COLUMN job_notes.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.job_notes.created_at IS 'Default created_at/updated_at';


--
-- Name: COLUMN job_notes.job_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.job_notes.job_id IS 'The job to which the note applies';


--
-- Name: COLUMN job_notes.note; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.job_notes.note IS 'The note';


--
-- Name: COLUMN job_notes.send_to_intake_user; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.job_notes.send_to_intake_user IS 'Should the note trigger a message to the job intake user';


--
-- Name: COLUMN job_notes.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.job_notes.updated_at IS 'Default created_at/updated_at';


--
-- Name: COLUMN job_notes.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.job_notes.user_id IS 'The user who created the note';


--
-- Name: job_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.job_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.job_notes_id_seq OWNED BY public.job_notes.id;


--
-- Name: judge_case_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.judge_case_reviews (
    id bigint NOT NULL,
    areas_for_improvement text[] DEFAULT '{}'::text[],
    attorney_id integer,
    comment text,
    complexity character varying,
    created_at timestamp without time zone NOT NULL,
    factors_not_considered text[] DEFAULT '{}'::text[],
    judge_id integer,
    location character varying,
    one_touch_initiative boolean,
    positive_feedback text[] DEFAULT '{}'::text[],
    quality character varying,
    task_id character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: judge_case_reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.judge_case_reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: judge_case_reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.judge_case_reviews_id_seq OWNED BY public.judge_case_reviews.id;


--
-- Name: judge_team_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.judge_team_roles (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    organizations_user_id integer,
    type character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE judge_team_roles; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.judge_team_roles IS 'Defines roles for individual members of judge teams';


--
-- Name: judge_team_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.judge_team_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: judge_team_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.judge_team_roles_id_seq OWNED BY public.judge_team_roles.id;


--
-- Name: legacy_appeals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legacy_appeals (
    id bigint NOT NULL,
    appeal_series_id bigint,
    closest_regional_office character varying,
    contaminated_water_at_camp_lejeune boolean DEFAULT false,
    created_at timestamp without time zone,
    dic_death_or_accrued_benefits_united_states boolean DEFAULT false,
    dispatched_to_station character varying,
    education_gi_bill_dependents_educational_assistance_scholars boolean DEFAULT false,
    foreign_claim_compensation_claims_dual_claims_appeals boolean DEFAULT false,
    foreign_pension_dic_all_other_foreign_countries boolean DEFAULT false,
    foreign_pension_dic_mexico_central_and_south_america_caribb boolean DEFAULT false,
    hearing_including_travel_board_video_conference boolean DEFAULT false,
    home_loan_guaranty boolean DEFAULT false,
    incarcerated_veterans boolean DEFAULT false,
    insurance boolean DEFAULT false,
    issues_pulled boolean,
    manlincon_compliance boolean DEFAULT false,
    mustard_gas boolean DEFAULT false,
    national_cemetery_administration boolean DEFAULT false,
    nonrating_issue boolean DEFAULT false,
    pension_united_states boolean DEFAULT false,
    private_attorney_or_agent boolean DEFAULT false,
    radiation boolean DEFAULT false,
    rice_compliance boolean DEFAULT false,
    spina_bifida boolean DEFAULT false,
    updated_at timestamp without time zone,
    us_territory_claim_american_samoa_guam_northern_mariana_isla boolean DEFAULT false,
    us_territory_claim_philippines boolean DEFAULT false,
    us_territory_claim_puerto_rico_and_virgin_islands boolean DEFAULT false,
    vacols_id character varying NOT NULL,
    vamc boolean DEFAULT false,
    vbms_id character varying,
    vocational_rehab boolean DEFAULT false,
    waiver_of_overpayment boolean DEFAULT false
);


--
-- Name: legacy_appeals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.legacy_appeals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legacy_appeals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.legacy_appeals_id_seq OWNED BY public.legacy_appeals.id;


--
-- Name: legacy_hearings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legacy_hearings (
    id bigint NOT NULL,
    appeal_id integer,
    created_at timestamp without time zone,
    created_by_id bigint,
    hearing_day_id bigint,
    military_service character varying,
    prepped boolean,
    summary text,
    updated_at timestamp without time zone,
    updated_by_id bigint,
    user_id integer,
    vacols_id character varying NOT NULL,
    witness character varying
);


--
-- Name: COLUMN legacy_hearings.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_hearings.created_at IS 'Automatic timestamp when row was created.';


--
-- Name: COLUMN legacy_hearings.created_by_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_hearings.created_by_id IS 'The ID of the user who created the Legacy Hearing';


--
-- Name: COLUMN legacy_hearings.hearing_day_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_hearings.hearing_day_id IS 'The hearing day the hearing will take place on';


--
-- Name: COLUMN legacy_hearings.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_hearings.updated_at IS 'Timestamp when record was last updated.';


--
-- Name: COLUMN legacy_hearings.updated_by_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_hearings.updated_by_id IS 'The ID of the user who most recently updated the Legacy Hearing';


--
-- Name: legacy_hearings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.legacy_hearings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legacy_hearings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.legacy_hearings_id_seq OWNED BY public.legacy_hearings.id;


--
-- Name: legacy_issue_optins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legacy_issue_optins (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    error character varying,
    optin_processed_at timestamp without time zone,
    original_disposition_code character varying,
    original_disposition_date date,
    request_issue_id bigint NOT NULL,
    rollback_created_at timestamp without time zone,
    rollback_processed_at timestamp without time zone,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE legacy_issue_optins; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.legacy_issue_optins IS 'When a VACOLS issue from a legacy appeal is opted-in to AMA, this table keeps track of the related request_issue, and the status of processing the opt-in, or rollback if the request issue is removed from a Decision Review.';


--
-- Name: COLUMN legacy_issue_optins.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_issue_optins.created_at IS 'When a Request Issue is connected to a VACOLS issue on a legacy appeal, and the Veteran has agreed to withdraw their legacy appeals, a legacy_issue_optin is created at the time the Decision Review is successfully intaken. This is used to indicate that the legacy issue should subsequently be opted into AMA in VACOLS. ';


--
-- Name: COLUMN legacy_issue_optins.optin_processed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_issue_optins.optin_processed_at IS 'The timestamp for when the opt-in was successfully processed, meaning it was updated in VACOLS as opted into AMA.';


--
-- Name: COLUMN legacy_issue_optins.original_disposition_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_issue_optins.original_disposition_code IS 'The original disposition code of the VACOLS issue being opted in. Stored in case the opt-in is rolled back.';


--
-- Name: COLUMN legacy_issue_optins.original_disposition_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_issue_optins.original_disposition_date IS 'The original disposition date of the VACOLS issue being opted in. Stored in case the opt-in is rolled back.';


--
-- Name: COLUMN legacy_issue_optins.request_issue_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_issue_optins.request_issue_id IS 'The request issue connected to the legacy VACOLS issue that has been opted in.';


--
-- Name: COLUMN legacy_issue_optins.rollback_created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_issue_optins.rollback_created_at IS 'Timestamp for when the connected request issue is removed from a Decision Review during edit, indicating that the opt-in needs to be rolled back.';


--
-- Name: COLUMN legacy_issue_optins.rollback_processed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_issue_optins.rollback_processed_at IS 'Timestamp for when a rolled back opt-in has successfully finished being rolled back.';


--
-- Name: COLUMN legacy_issue_optins.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.legacy_issue_optins.updated_at IS 'Automatically populated when the record is updated.';


--
-- Name: legacy_issue_optins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.legacy_issue_optins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legacy_issue_optins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.legacy_issue_optins_id_seq OWNED BY public.legacy_issue_optins.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    detail_id integer,
    detail_type character varying,
    read_at timestamp without time zone,
    text character varying,
    updated_at timestamp without time zone NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: COLUMN messages.detail_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.detail_id IS 'ID of the related object';


--
-- Name: COLUMN messages.detail_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.detail_type IS 'Model name of the related object';


--
-- Name: COLUMN messages.read_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.read_at IS 'When the message was read';


--
-- Name: COLUMN messages.text; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.text IS 'The message';


--
-- Name: COLUMN messages.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.messages.user_id IS 'The user for whom the message is intended';


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: non_availabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.non_availabilities (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    date date,
    object_identifier character varying NOT NULL,
    schedule_period_id bigint NOT NULL,
    type character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: non_availabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.non_availabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: non_availabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.non_availabilities_id_seq OWNED BY public.non_availabilities.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id bigint NOT NULL,
    created_at timestamp without time zone,
    name character varying,
    participant_id character varying,
    role character varying,
    type character varying,
    updated_at timestamp without time zone,
    url character varying
);


--
-- Name: COLUMN organizations.participant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.participant_id IS 'Organizations BGS partipant id';


--
-- Name: COLUMN organizations.role; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.role IS 'Role users in organization must have, if present';


--
-- Name: COLUMN organizations.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.type IS 'Single table inheritance';


--
-- Name: COLUMN organizations.url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.url IS 'Unique portion of the organization queue url';


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organizations_id_seq OWNED BY public.organizations.id;


--
-- Name: organizations_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations_users (
    id bigint NOT NULL,
    admin boolean DEFAULT false,
    created_at timestamp without time zone,
    organization_id integer,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: organizations_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organizations_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organizations_users_id_seq OWNED BY public.organizations_users.id;


--
-- Name: people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.people (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    date_of_birth date,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    name_suffix character varying,
    participant_id character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: COLUMN people.first_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.people.first_name IS 'Person first name, cached from BGS';


--
-- Name: COLUMN people.last_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.people.last_name IS 'Person last name, cached from BGS';


--
-- Name: COLUMN people.middle_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.people.middle_name IS 'Person middle name, cached from BGS';


--
-- Name: COLUMN people.name_suffix; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.people.name_suffix IS 'Person name suffix, cached from BGS';


--
-- Name: people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.people_id_seq OWNED BY public.people.id;


--
-- Name: post_decision_motions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_decision_motions (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    disposition character varying,
    task_id bigint,
    updated_at timestamp without time zone NOT NULL,
    vacate_type character varying,
    vacated_decision_issue_ids integer[]
);


--
-- Name: TABLE post_decision_motions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.post_decision_motions IS 'Stores the disposition and associated task of post-decisional motions handled by the Litigation Support Team: Motion for Reconsideration, Motion to Vacate, and Clear and Unmistakeable Error.';


--
-- Name: COLUMN post_decision_motions.disposition; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.post_decision_motions.disposition IS 'Possible options are Grant, Deny, Withdraw, and Dismiss';


--
-- Name: COLUMN post_decision_motions.vacate_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.post_decision_motions.vacate_type IS 'Granted motion to vacate can be either Straight Vacate and Readjudication or Vacate and De Novo.';


--
-- Name: COLUMN post_decision_motions.vacated_decision_issue_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.post_decision_motions.vacated_decision_issue_ids IS 'When a motion to vacate is partially granted, this includes an array of the appeal''s decision issue IDs that were chosen for vacatur in this post-decision motion';


--
-- Name: post_decision_motions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.post_decision_motions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_decision_motions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.post_decision_motions_id_seq OWNED BY public.post_decision_motions.id;


--
-- Name: ramp_closed_appeals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ramp_closed_appeals (
    id integer NOT NULL,
    closed_on timestamp without time zone,
    created_at timestamp without time zone,
    nod_date date,
    partial_closure_issue_sequence_ids character varying[],
    ramp_election_id integer,
    updated_at timestamp without time zone,
    vacols_id character varying NOT NULL
);


--
-- Name: TABLE ramp_closed_appeals; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ramp_closed_appeals IS 'Keeps track of legacy appeals that are closed or partially closed in VACOLS due to being transitioned to a RAMP election.  This data can be used to rollback the RAMP Election if needed.';


--
-- Name: COLUMN ramp_closed_appeals.closed_on; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_closed_appeals.closed_on IS 'The datetime that the legacy appeal was closed in VACOLS and opted into RAMP.';


--
-- Name: COLUMN ramp_closed_appeals.nod_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_closed_appeals.nod_date IS 'The date when the Veteran filed a Notice of Disagreement for the original claims decision in the legacy system.';


--
-- Name: COLUMN ramp_closed_appeals.partial_closure_issue_sequence_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_closed_appeals.partial_closure_issue_sequence_ids IS 'If the entire legacy appeal could not be closed and moved to the RAMP Election, the VACOLS sequence IDs of issues on the legacy appeal which were closed are stored here, indicating that it was a partial closure.';


--
-- Name: COLUMN ramp_closed_appeals.ramp_election_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_closed_appeals.ramp_election_id IS 'The ID of the RAMP election that closed the legacy appeal.';


--
-- Name: COLUMN ramp_closed_appeals.vacols_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_closed_appeals.vacols_id IS 'The VACOLS BFKEY of the legacy appeal that has been closed and opted into RAMP.';


--
-- Name: ramp_closed_appeals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ramp_closed_appeals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ramp_closed_appeals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ramp_closed_appeals_id_seq OWNED BY public.ramp_closed_appeals.id;


--
-- Name: ramp_election_rollbacks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ramp_election_rollbacks (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    ramp_election_id bigint,
    reason character varying,
    reopened_vacols_ids character varying[],
    updated_at timestamp without time zone NOT NULL,
    user_id bigint
);


--
-- Name: TABLE ramp_election_rollbacks; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ramp_election_rollbacks IS 'If a RAMP election needs to get rolled back, for example if the EP is canceled, it is tracked here. Also any VACOLS issues that were closed in the legacy system and opted into RAMP are re-opened in the legacy system.';


--
-- Name: COLUMN ramp_election_rollbacks.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_election_rollbacks.created_at IS 'Timestamp for when the rollback was created.';


--
-- Name: COLUMN ramp_election_rollbacks.ramp_election_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_election_rollbacks.ramp_election_id IS 'The ID of the RAMP Election being rolled back.';


--
-- Name: COLUMN ramp_election_rollbacks.reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_election_rollbacks.reason IS 'The reason for rolling back the RAMP Election. Rollbacks happen automatically for canceled RAMP Election End Products, but can also happen for other reason such as by request.';


--
-- Name: COLUMN ramp_election_rollbacks.reopened_vacols_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_election_rollbacks.reopened_vacols_ids IS 'The IDs of any legacy appeals which were reopened as a result of rolling back the RAMP Election, corresponding to the VACOLS BFKEY.';


--
-- Name: COLUMN ramp_election_rollbacks.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_election_rollbacks.updated_at IS 'Timestamp for when the rollback was last updated.';


--
-- Name: COLUMN ramp_election_rollbacks.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_election_rollbacks.user_id IS 'The user who created the RAMP Election rollback, typically a system user.';


--
-- Name: ramp_election_rollbacks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ramp_election_rollbacks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ramp_election_rollbacks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ramp_election_rollbacks_id_seq OWNED BY public.ramp_election_rollbacks.id;


--
-- Name: ramp_elections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ramp_elections (
    id integer NOT NULL,
    created_at timestamp without time zone,
    established_at timestamp without time zone,
    notice_date date,
    option_selected character varying,
    receipt_date date,
    updated_at timestamp without time zone,
    veteran_file_number character varying NOT NULL
);


--
-- Name: TABLE ramp_elections; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ramp_elections IS 'Intake data for RAMP elections.';


--
-- Name: COLUMN ramp_elections.established_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_elections.established_at IS 'Timestamp for when the review successfully established, including any related actions such as establishing a claim in VBMS if applicable.';


--
-- Name: COLUMN ramp_elections.notice_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_elections.notice_date IS 'The date that the Veteran was notified of their option to opt their legacy appeals into RAMP.';


--
-- Name: COLUMN ramp_elections.option_selected; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_elections.option_selected IS 'Indicates whether the Veteran selected for their RAMP election to be processed as a higher level review (with or without a hearing), a supplemental claim, or a board appeal.';


--
-- Name: COLUMN ramp_elections.receipt_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_elections.receipt_date IS 'The date that the RAMP form was received by central mail.';


--
-- Name: COLUMN ramp_elections.veteran_file_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_elections.veteran_file_number IS 'The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran.';


--
-- Name: ramp_elections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ramp_elections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ramp_elections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ramp_elections_id_seq OWNED BY public.ramp_elections.id;


--
-- Name: ramp_issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ramp_issues (
    id integer NOT NULL,
    contention_reference_id character varying,
    created_at timestamp without time zone,
    description character varying NOT NULL,
    review_id integer NOT NULL,
    review_type character varying NOT NULL,
    source_issue_id integer,
    updated_at timestamp without time zone
);


--
-- Name: TABLE ramp_issues; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ramp_issues IS 'Issues added to an end product as contentions for RAMP reviews. For RAMP elections, these are created in VBMS after the end product is established and updated in Caseflow when the end product is synced. For RAMP refilings, these are selected from the RAMP election''s issues and added to the RAMP refiling end product that is established.';


--
-- Name: COLUMN ramp_issues.contention_reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_issues.contention_reference_id IS 'The ID of the contention created in VBMS that corresponds to the RAMP issue.';


--
-- Name: COLUMN ramp_issues.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_issues.description IS 'The description of the contention in VBMS.';


--
-- Name: COLUMN ramp_issues.review_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_issues.review_id IS 'The ID of the RAMP election or RAMP refiling for this issue.';


--
-- Name: COLUMN ramp_issues.review_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_issues.review_type IS 'The type of RAMP review the issue is on, indicating whether this is a RAMP election issue or a RAMP refiling issue.';


--
-- Name: COLUMN ramp_issues.source_issue_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_issues.source_issue_id IS 'If a RAMP election issue added to a RAMP refiling, it is the source issue for the corresponding RAMP refiling issue.';


--
-- Name: ramp_issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ramp_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ramp_issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ramp_issues_id_seq OWNED BY public.ramp_issues.id;


--
-- Name: ramp_refilings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ramp_refilings (
    id integer NOT NULL,
    appeal_docket character varying,
    created_at timestamp without time zone,
    established_at timestamp without time zone,
    establishment_processed_at timestamp without time zone,
    establishment_submitted_at timestamp without time zone,
    has_ineligible_issue boolean,
    option_selected character varying,
    receipt_date date,
    updated_at timestamp without time zone,
    veteran_file_number character varying NOT NULL
);


--
-- Name: TABLE ramp_refilings; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ramp_refilings IS 'Intake data for RAMP refilings, also known as RAMP selection.';


--
-- Name: COLUMN ramp_refilings.appeal_docket; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_refilings.appeal_docket IS 'When the RAMP refiling option selected is appeal, they can select hearing, direct review or evidence submission as the appeal docket.';


--
-- Name: COLUMN ramp_refilings.established_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_refilings.established_at IS 'Timestamp for when the review successfully established, including any related actions such as establishing a claim in VBMS if applicable.';


--
-- Name: COLUMN ramp_refilings.establishment_processed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_refilings.establishment_processed_at IS 'Timestamp for when the end product establishments for the RAMP review finished processing.';


--
-- Name: COLUMN ramp_refilings.establishment_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_refilings.establishment_submitted_at IS 'Timestamp for when an intake for a review was submitted by the user.';


--
-- Name: COLUMN ramp_refilings.has_ineligible_issue; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_refilings.has_ineligible_issue IS 'Selected by the user during intake, indicates whether the Veteran listed ineligible issues on their refiling.';


--
-- Name: COLUMN ramp_refilings.option_selected; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_refilings.option_selected IS 'Which lane the RAMP refiling is for, between appeal, higher level review, and supplemental claim.';


--
-- Name: COLUMN ramp_refilings.receipt_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_refilings.receipt_date IS 'Receipt date of the RAMP form.';


--
-- Name: COLUMN ramp_refilings.veteran_file_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ramp_refilings.veteran_file_number IS 'The VBA corporate file number of the Veteran for this review. There can sometimes be more than one file number per Veteran.';


--
-- Name: ramp_refilings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ramp_refilings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ramp_refilings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ramp_refilings_id_seq OWNED BY public.ramp_refilings.id;


--
-- Name: record_synced_by_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.record_synced_by_jobs (
    id bigint NOT NULL,
    created_at timestamp without time zone,
    error character varying,
    processed_at timestamp without time zone,
    record_id bigint,
    record_type character varying,
    sync_job_name character varying,
    updated_at timestamp without time zone
);


--
-- Name: record_synced_by_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.record_synced_by_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: record_synced_by_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.record_synced_by_jobs_id_seq OWNED BY public.record_synced_by_jobs.id;


--
-- Name: remand_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.remand_reasons (
    id bigint NOT NULL,
    code character varying,
    created_at timestamp without time zone NOT NULL,
    decision_issue_id integer,
    post_aoj boolean,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: remand_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.remand_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: remand_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.remand_reasons_id_seq OWNED BY public.remand_reasons.id;


--
-- Name: request_decision_issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.request_decision_issues (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    decision_issue_id integer,
    deleted_at timestamp without time zone,
    request_issue_id integer,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE request_decision_issues; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.request_decision_issues IS 'Join table for the has and belongs to many to many relationship between request issues and decision issues.';


--
-- Name: COLUMN request_decision_issues.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_decision_issues.created_at IS 'Automatic timestamp when row was created.';


--
-- Name: COLUMN request_decision_issues.decision_issue_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_decision_issues.decision_issue_id IS 'The ID of the decision issue.';


--
-- Name: COLUMN request_decision_issues.request_issue_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_decision_issues.request_issue_id IS 'The ID of the request issue.';


--
-- Name: COLUMN request_decision_issues.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_decision_issues.updated_at IS 'Automatically populated when the record is updated.';


--
-- Name: request_decision_issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.request_decision_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_decision_issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.request_decision_issues_id_seq OWNED BY public.request_decision_issues.id;


--
-- Name: request_issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.request_issues (
    id bigint NOT NULL,
    benefit_type character varying NOT NULL,
    closed_at timestamp without time zone,
    closed_status character varying,
    contention_reference_id integer,
    contention_removed_at timestamp without time zone,
    contention_updated_at timestamp without time zone,
    contested_decision_issue_id integer,
    contested_issue_description character varying,
    contested_rating_decision_reference_id character varying,
    contested_rating_issue_diagnostic_code character varying,
    contested_rating_issue_profile_date character varying,
    contested_rating_issue_reference_id character varying,
    corrected_by_request_issue_id integer,
    correction_type character varying,
    created_at timestamp without time zone,
    decision_date date,
    decision_review_id bigint,
    decision_review_type character varying,
    decision_sync_attempted_at timestamp without time zone,
    decision_sync_canceled_at timestamp without time zone,
    decision_sync_error character varying,
    decision_sync_last_submitted_at timestamp without time zone,
    decision_sync_processed_at timestamp without time zone,
    decision_sync_submitted_at timestamp without time zone,
    edited_description character varying,
    end_product_establishment_id integer,
    ineligible_due_to_id bigint,
    ineligible_reason character varying,
    is_unidentified boolean,
    nonrating_issue_category character varying,
    nonrating_issue_description character varying,
    notes text,
    ramp_claim_id character varying,
    rating_issue_associated_at timestamp without time zone,
    unidentified_issue_text character varying,
    untimely_exemption boolean,
    untimely_exemption_notes text,
    updated_at timestamp without time zone,
    vacols_id character varying,
    vacols_sequence_id integer,
    veteran_participant_id character varying
);


--
-- Name: TABLE request_issues; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.request_issues IS 'Each Request Issue represents the Veteran''s response to a Rating Issue. Request Issues come in three flavors: rating, nonrating, and unidentified. They are attached to a Decision Review and (for those that track contentions) an End Product Establishment. A Request Issue can contest a rating issue, a decision issue, or a nonrating issue without a decision issue.';


--
-- Name: COLUMN request_issues.benefit_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.benefit_type IS 'The Line of Business the issue is connected with.';


--
-- Name: COLUMN request_issues.closed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.closed_at IS 'Timestamp when the request issue was closed. The reason it was closed is in closed_status.';


--
-- Name: COLUMN request_issues.closed_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.closed_status IS 'Indicates whether the request issue is closed, for example if it was removed from a Decision Review, the associated End Product got canceled, the Decision Review was withdrawn.';


--
-- Name: COLUMN request_issues.contention_reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.contention_reference_id IS 'The ID of the contention created on the End Product for this request issue. This is populated after the contention is created in VBMS.';


--
-- Name: COLUMN request_issues.contention_removed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.contention_removed_at IS 'When a request issue is removed from a Decision Review during an edit, if it has a contention in VBMS that is also removed. This field indicates when the contention has successfully been removed in VBMS.';


--
-- Name: COLUMN request_issues.contention_updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.contention_updated_at IS 'Timestamp indicating when a contention was successfully updated in VBMS.';


--
-- Name: COLUMN request_issues.contested_decision_issue_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.contested_decision_issue_id IS 'The ID of the decision issue that this request issue contests. A Request issue will contest either a rating issue or a decision issue';


--
-- Name: COLUMN request_issues.contested_issue_description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.contested_issue_description IS 'Description of the contested rating or decision issue. Will be either a rating issue''s decision text or a decision issue''s description.';


--
-- Name: COLUMN request_issues.contested_rating_decision_reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.contested_rating_decision_reference_id IS 'The BGS id for contested rating decisions. These may not have corresponding contested_rating_issue_reference_id values.';


--
-- Name: COLUMN request_issues.contested_rating_issue_diagnostic_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.contested_rating_issue_diagnostic_code IS 'If the contested issue is a rating issue, this is the rating issue''s diagnostic code. Will be nil if this request issue contests a decision issue.';


--
-- Name: COLUMN request_issues.contested_rating_issue_profile_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.contested_rating_issue_profile_date IS 'If the contested issue is a rating issue, this is the rating issue''s profile date. Will be nil if this request issue contests a decision issue.';


--
-- Name: COLUMN request_issues.contested_rating_issue_reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.contested_rating_issue_reference_id IS 'If the contested issue is a rating issue, this is the rating issue''s reference id. Will be nil if this request issue contests a decision issue.';


--
-- Name: COLUMN request_issues.corrected_by_request_issue_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.corrected_by_request_issue_id IS 'If this request issue has been corrected, the ID of the new correction request issue. This is needed for EP 930.';


--
-- Name: COLUMN request_issues.correction_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.correction_type IS 'EP 930 correction type. Allowed values: control, local_quality_error, national_quality_error where ''control'' is a regular correction, ''local_quality_error'' was found after the fact by a local quality review team, and ''national_quality_error'' was similarly found by a national quality review team. This is needed for EP 930.';


--
-- Name: COLUMN request_issues.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.created_at IS 'Automatic timestamp when row was created';


--
-- Name: COLUMN request_issues.decision_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.decision_date IS 'Either the rating issue''s promulgation date, the decision issue''s approx decision date or the decision date entered by the user (for nonrating and unidentified issues)';


--
-- Name: COLUMN request_issues.decision_review_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.decision_review_id IS 'ID of the decision review that this request issue belongs to';


--
-- Name: COLUMN request_issues.decision_review_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.decision_review_type IS 'Class name of the decision review that this request issue belongs to';


--
-- Name: COLUMN request_issues.decision_sync_attempted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.decision_sync_attempted_at IS 'Async job processing last attempted timestamp';


--
-- Name: COLUMN request_issues.decision_sync_canceled_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.decision_sync_canceled_at IS 'Timestamp when job was abandoned';


--
-- Name: COLUMN request_issues.decision_sync_error; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.decision_sync_error IS 'Async job processing last error message';


--
-- Name: COLUMN request_issues.decision_sync_last_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.decision_sync_last_submitted_at IS 'Async job processing most recent start timestamp';


--
-- Name: COLUMN request_issues.decision_sync_processed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.decision_sync_processed_at IS 'Async job processing completed timestamp';


--
-- Name: COLUMN request_issues.decision_sync_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.decision_sync_submitted_at IS 'Async job processing start timestamp';


--
-- Name: COLUMN request_issues.edited_description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.edited_description IS 'The edited description for the contested issue, optionally entered by the user.';


--
-- Name: COLUMN request_issues.end_product_establishment_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.end_product_establishment_id IS 'The ID of the End Product Establishment created for this request issue.';


--
-- Name: COLUMN request_issues.ineligible_due_to_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.ineligible_due_to_id IS 'If a request issue is ineligible due to another request issue, for example that issue is already being actively reviewed, then the ID of the other request issue is stored here.';


--
-- Name: COLUMN request_issues.ineligible_reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.ineligible_reason IS 'The reason for a Request Issue being ineligible. If a Request Issue has an ineligible_reason, it is still captured, but it will not get a contention in VBMS or a decision.';


--
-- Name: COLUMN request_issues.is_unidentified; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.is_unidentified IS 'Indicates whether a Request Issue is unidentified, meaning it wasn''t found in the list of contestable issues, and is not a new nonrating issue. Contentions for unidentified issues are created on a rating End Product if processed in VBMS but without the issue description, and someone is required to edit it in Caseflow before proceeding with the decision.';


--
-- Name: COLUMN request_issues.nonrating_issue_category; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.nonrating_issue_category IS 'The category selected for nonrating request issues. These vary by business line.';


--
-- Name: COLUMN request_issues.nonrating_issue_description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.nonrating_issue_description IS 'The user entered description if the issue is a nonrating issue';


--
-- Name: COLUMN request_issues.notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.notes IS 'Notes added by the Claims Assistant when adding request issues. This may be used to capture handwritten notes on the form, or other comments the CA wants to capture.';


--
-- Name: COLUMN request_issues.ramp_claim_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.ramp_claim_id IS 'If a rating issue was created as a result of an issue intaken for a RAMP Review, it will be connected to the former RAMP issue by its End Product''s claim ID.';


--
-- Name: COLUMN request_issues.rating_issue_associated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.rating_issue_associated_at IS 'Timestamp when a contention and its contested rating issue are associated in VBMS.';


--
-- Name: COLUMN request_issues.unidentified_issue_text; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.unidentified_issue_text IS 'User entered description if the request issue is neither a rating or a nonrating issue';


--
-- Name: COLUMN request_issues.untimely_exemption; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.untimely_exemption IS 'If the contested issue''s decision date was more than a year before the receipt date, it is considered untimely (unless it is a Supplemental Claim). However, an exemption to the timeliness can be requested. If so, it is indicated here.';


--
-- Name: COLUMN request_issues.untimely_exemption_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.untimely_exemption_notes IS 'Notes related to the untimeliness exemption requested.';


--
-- Name: COLUMN request_issues.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.updated_at IS 'Automatic timestamp whenever the record changes.';


--
-- Name: COLUMN request_issues.vacols_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.vacols_id IS 'The vacols_id of the legacy appeal that had an issue found to match the request issue.';


--
-- Name: COLUMN request_issues.vacols_sequence_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.vacols_sequence_id IS 'The vacols_sequence_id, for the specific issue on the legacy appeal which the Claims Assistant determined to match the request issue on the Decision Review. A combination of the vacols_id (for the legacy appeal), and vacols_sequence_id (for which issue on the legacy appeal), is required to identify the issue being opted-in.';


--
-- Name: COLUMN request_issues.veteran_participant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues.veteran_participant_id IS 'The veteran participant ID. This should be unique in upstream systems and used in the future to reconcile duplicates.';


--
-- Name: request_issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.request_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.request_issues_id_seq OWNED BY public.request_issues.id;


--
-- Name: request_issues_updates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.request_issues_updates (
    id bigint NOT NULL,
    after_request_issue_ids integer[] NOT NULL,
    attempted_at timestamp without time zone,
    before_request_issue_ids integer[] NOT NULL,
    canceled_at timestamp without time zone,
    corrected_request_issue_ids integer[],
    created_at timestamp without time zone,
    edited_request_issue_ids integer[],
    error character varying,
    last_submitted_at timestamp without time zone,
    processed_at timestamp without time zone,
    review_id bigint NOT NULL,
    review_type character varying NOT NULL,
    submitted_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id bigint NOT NULL,
    withdrawn_request_issue_ids integer[]
);


--
-- Name: TABLE request_issues_updates; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.request_issues_updates IS 'Keeps track of edits to request issues on a decision review that happen after the initial intake, such as removing and adding issues.  When the decision review is processed in VBMS, this also tracks whether adding or removing contentions in VBMS for the update has succeeded.';


--
-- Name: COLUMN request_issues_updates.after_request_issue_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.after_request_issue_ids IS 'An array of the active request issue IDs after a user has finished editing a decision review. Used with before_request_issue_ids to determine appropriate actions (such as which contentions need to be added).';


--
-- Name: COLUMN request_issues_updates.attempted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.attempted_at IS 'Timestamp for when the request issue update processing was last attempted.';


--
-- Name: COLUMN request_issues_updates.before_request_issue_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.before_request_issue_ids IS 'An array of the active request issue IDs previously on the decision review before this editing session. Used with after_request_issue_ids to determine appropriate actions (such as which contentions need to be removed).';


--
-- Name: COLUMN request_issues_updates.canceled_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.canceled_at IS 'Timestamp when job was abandoned';


--
-- Name: COLUMN request_issues_updates.corrected_request_issue_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.corrected_request_issue_ids IS 'An array of the request issue IDs that were corrected during this request issues update.';


--
-- Name: COLUMN request_issues_updates.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.created_at IS 'Timestamp when record was initially created';


--
-- Name: COLUMN request_issues_updates.edited_request_issue_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.edited_request_issue_ids IS 'An array of the request issue IDs that were edited during this request issues update';


--
-- Name: COLUMN request_issues_updates.error; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.error IS 'The error message if the last attempt at processing the request issues update was not successful.';


--
-- Name: COLUMN request_issues_updates.last_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.last_submitted_at IS 'Timestamp for when the processing for the request issues update was last submitted. Used to determine how long to continue retrying the processing job. Can be reset to allow for additional retries.';


--
-- Name: COLUMN request_issues_updates.processed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.processed_at IS 'Timestamp for when the request issue update successfully completed processing.';


--
-- Name: COLUMN request_issues_updates.review_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.review_id IS 'The ID of the decision review edited.';


--
-- Name: COLUMN request_issues_updates.review_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.review_type IS 'The type of the decision review edited.';


--
-- Name: COLUMN request_issues_updates.submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.submitted_at IS 'Timestamp when the request issues update was originally submitted.';


--
-- Name: COLUMN request_issues_updates.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.updated_at IS 'Timestamp when record was last updated.';


--
-- Name: COLUMN request_issues_updates.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.user_id IS 'The ID of the user who edited the decision review.';


--
-- Name: COLUMN request_issues_updates.withdrawn_request_issue_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_issues_updates.withdrawn_request_issue_ids IS 'An array of the request issue IDs that were withdrawn during this request issues update.';


--
-- Name: request_issues_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.request_issues_updates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_issues_updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.request_issues_updates_id_seq OWNED BY public.request_issues_updates.id;


--
-- Name: schedule_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schedule_periods (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    end_date date NOT NULL,
    file_name character varying NOT NULL,
    finalized boolean,
    start_date date NOT NULL,
    type character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: schedule_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schedule_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schedule_periods_id_seq OWNED BY public.schedule_periods.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: special_issue_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.special_issue_lists (
    id bigint NOT NULL,
    appeal_id bigint,
    appeal_type character varying,
    contaminated_water_at_camp_lejeune boolean DEFAULT false,
    created_at timestamp without time zone,
    dic_death_or_accrued_benefits_united_states boolean DEFAULT false,
    education_gi_bill_dependents_educational_assistance_scholars boolean DEFAULT false,
    foreign_claim_compensation_claims_dual_claims_appeals boolean DEFAULT false,
    foreign_pension_dic_all_other_foreign_countries boolean DEFAULT false,
    foreign_pension_dic_mexico_central_and_south_america_caribb boolean DEFAULT false,
    hearing_including_travel_board_video_conference boolean DEFAULT false,
    home_loan_guaranty boolean DEFAULT false,
    incarcerated_veterans boolean DEFAULT false,
    insurance boolean DEFAULT false,
    manlincon_compliance boolean DEFAULT false,
    mustard_gas boolean DEFAULT false,
    national_cemetery_administration boolean DEFAULT false,
    nonrating_issue boolean DEFAULT false,
    pension_united_states boolean DEFAULT false,
    private_attorney_or_agent boolean DEFAULT false,
    radiation boolean DEFAULT false,
    rice_compliance boolean DEFAULT false,
    spina_bifida boolean DEFAULT false,
    updated_at timestamp without time zone,
    us_territory_claim_american_samoa_guam_northern_mariana_isla boolean DEFAULT false,
    us_territory_claim_philippines boolean DEFAULT false,
    us_territory_claim_puerto_rico_and_virgin_islands boolean DEFAULT false,
    vamc boolean DEFAULT false,
    vocational_rehab boolean DEFAULT false,
    waiver_of_overpayment boolean DEFAULT false
);


--
-- Name: special_issue_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.special_issue_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: special_issue_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.special_issue_lists_id_seq OWNED BY public.special_issue_lists.id;


--
-- Name: supplemental_claims; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supplemental_claims (
    id bigint NOT NULL,
    benefit_type character varying,
    created_at timestamp without time zone,
    decision_review_remanded_id bigint,
    decision_review_remanded_type character varying,
    establishment_attempted_at timestamp without time zone,
    establishment_canceled_at timestamp without time zone,
    establishment_error character varying,
    establishment_last_submitted_at timestamp without time zone,
    establishment_processed_at timestamp without time zone,
    establishment_submitted_at timestamp without time zone,
    legacy_opt_in_approved boolean,
    receipt_date date,
    updated_at timestamp without time zone,
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    veteran_file_number character varying NOT NULL,
    veteran_is_not_claimant boolean
);


--
-- Name: TABLE supplemental_claims; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.supplemental_claims IS 'Intake data for Supplemental Claims.';


--
-- Name: COLUMN supplemental_claims.benefit_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.benefit_type IS 'The benefit type selected by the Veteran on their form, also known as a Line of Business.';


--
-- Name: COLUMN supplemental_claims.decision_review_remanded_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.decision_review_remanded_id IS 'If an Appeal or Higher Level Review decision is remanded, including Duty to Assist errors, it automatically generates a new Supplemental Claim.  If this Supplemental Claim was generated, then the ID of the original Decision Review with the remanded decision is stored here.';


--
-- Name: COLUMN supplemental_claims.decision_review_remanded_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.decision_review_remanded_type IS 'The type of the Decision Review remanded if applicable, used with decision_review_remanded_id to as a composite key to identify the remanded Decision Review.';


--
-- Name: COLUMN supplemental_claims.establishment_attempted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.establishment_attempted_at IS 'Timestamp for the most recent attempt at establishing a claim.';


--
-- Name: COLUMN supplemental_claims.establishment_canceled_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.establishment_canceled_at IS 'Timestamp when job was abandoned';


--
-- Name: COLUMN supplemental_claims.establishment_error; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.establishment_error IS 'The error captured for the most recent attempt at establishing a claim if it failed.  This is removed once establishing the claim succeeds.';


--
-- Name: COLUMN supplemental_claims.establishment_last_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.establishment_last_submitted_at IS 'Timestamp for the latest attempt at establishing the End Products for the Decision Review.';


--
-- Name: COLUMN supplemental_claims.establishment_processed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.establishment_processed_at IS 'Timestamp for when the End Product Establishments for the Decision Review successfully finished processing.';


--
-- Name: COLUMN supplemental_claims.establishment_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.establishment_submitted_at IS 'Timestamp for when the Supplemental Claim was submitted by a Claims Assistant. This adds the End Product Establishment to a job to finish processing asynchronously.';


--
-- Name: COLUMN supplemental_claims.legacy_opt_in_approved; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.legacy_opt_in_approved IS 'Indicates whether a Veteran opted to withdraw their Supplemental Claim request issues from the legacy system if a matching issue is found. If there is a matching legacy issue and it is not withdrawn, then that issue is ineligible to be a new request issue and a contention will not be created for it.';


--
-- Name: COLUMN supplemental_claims.receipt_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.receipt_date IS 'The date that the Supplemental Claim form was received by central mail. Only issues decided prior to the receipt date will show up as contestable issues.  It is also the claim date for any associated end products that are established. Supplemental Claims do not have the same timeliness restriction on contestable issues as Appeals and Higher Level Reviews.';


--
-- Name: COLUMN supplemental_claims.uuid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.uuid IS 'The universally unique identifier for the Supplemental Claim. Can be used to link to the claim after it is completed.';


--
-- Name: COLUMN supplemental_claims.veteran_file_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.veteran_file_number IS 'The file number of the Veteran that the Supplemental Claim is for.';


--
-- Name: COLUMN supplemental_claims.veteran_is_not_claimant; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supplemental_claims.veteran_is_not_claimant IS 'Indicates whether the Veteran is the claimant on the Supplemental Claim form, or if the claimant is someone else like a spouse or a child. Must be TRUE if the Veteran is deceased.';


--
-- Name: supplemental_claims_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.supplemental_claims_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: supplemental_claims_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.supplemental_claims_id_seq OWNED BY public.supplemental_claims.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    text character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: task_timers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_timers (
    id bigint NOT NULL,
    attempted_at timestamp without time zone,
    canceled_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    error character varying,
    last_submitted_at timestamp without time zone,
    processed_at timestamp without time zone,
    submitted_at timestamp without time zone,
    task_id bigint NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE task_timers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.task_timers IS 'Task timers allow tasks to be run asynchronously after some future date, like EvidenceSubmissionWindowTask.';


--
-- Name: COLUMN task_timers.attempted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_timers.attempted_at IS 'Async timestamp for most recent attempt to run.';


--
-- Name: COLUMN task_timers.canceled_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_timers.canceled_at IS 'Timestamp when job was abandoned';


--
-- Name: COLUMN task_timers.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_timers.created_at IS 'Automatic timestamp for record creation.';


--
-- Name: COLUMN task_timers.error; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_timers.error IS 'Async any error message from most recent failed attempt to run.';


--
-- Name: COLUMN task_timers.last_submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_timers.last_submitted_at IS 'Async timestamp for most recent job start.';


--
-- Name: COLUMN task_timers.processed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_timers.processed_at IS 'Async timestamp for when the job completes successfully.';


--
-- Name: COLUMN task_timers.submitted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_timers.submitted_at IS 'Async timestamp for initial job start.';


--
-- Name: COLUMN task_timers.task_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_timers.task_id IS 'ID of the Task to be run.';


--
-- Name: COLUMN task_timers.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_timers.updated_at IS 'Automatic timestmap for record update.';


--
-- Name: task_timers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.task_timers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: task_timers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.task_timers_id_seq OWNED BY public.task_timers.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id bigint NOT NULL,
    appeal_id integer NOT NULL,
    appeal_type character varying NOT NULL,
    assigned_at timestamp without time zone,
    assigned_by_id integer,
    assigned_to_id integer NOT NULL,
    assigned_to_type character varying NOT NULL,
    closed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    instructions text[] DEFAULT '{}'::text[],
    on_hold_duration integer,
    parent_id integer,
    placed_on_hold_at timestamp without time zone,
    started_at timestamp without time zone,
    status character varying DEFAULT 'assigned'::character varying,
    type character varying,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- Name: team_quotas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_quotas (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    date date NOT NULL,
    task_type character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_count integer
);


--
-- Name: team_quotas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_quotas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_quotas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_quotas_id_seq OWNED BY public.team_quotas.id;


--
-- Name: transcriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transcriptions (
    id bigint NOT NULL,
    created_at timestamp without time zone,
    expected_return_date date,
    hearing_id bigint,
    problem_notice_sent_date date,
    problem_type character varying,
    requested_remedy character varying,
    sent_to_transcriber_date date,
    task_number character varying,
    transcriber character varying,
    updated_at timestamp without time zone,
    uploaded_to_vbms_date date
);


--
-- Name: transcriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transcriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transcriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transcriptions_id_seq OWNED BY public.transcriptions.id;


--
-- Name: user_quotas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_quotas (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    locked_task_count integer,
    team_quota_id integer NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: user_quotas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_quotas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_quotas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_quotas_id_seq OWNED BY public.user_quotas.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    created_at timestamp without time zone,
    css_id character varying NOT NULL,
    efolder_documents_fetched_at timestamp without time zone,
    email character varying,
    full_name character varying,
    last_login_at timestamp without time zone,
    roles character varying[],
    selected_regional_office character varying,
    station_id character varying NOT NULL,
    status character varying DEFAULT 'active'::character varying,
    status_updated_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: COLUMN users.efolder_documents_fetched_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.efolder_documents_fetched_at IS 'Date when efolder documents were cached in s3 for this user';


--
-- Name: COLUMN users.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.status IS 'Whether or not the user is an active user of caseflow';


--
-- Name: COLUMN users.status_updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.status_updated_at IS 'When the user''s status was last updated';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vbms_uploaded_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vbms_uploaded_documents (
    id bigint NOT NULL,
    appeal_id bigint NOT NULL,
    attempted_at timestamp without time zone,
    canceled_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    document_type character varying NOT NULL,
    error character varying,
    last_submitted_at timestamp without time zone,
    processed_at timestamp without time zone,
    submitted_at timestamp without time zone,
    updated_at timestamp without time zone NOT NULL,
    uploaded_to_vbms_at timestamp without time zone
);


--
-- Name: COLUMN vbms_uploaded_documents.canceled_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vbms_uploaded_documents.canceled_at IS 'Timestamp when job was abandoned';


--
-- Name: vbms_uploaded_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vbms_uploaded_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vbms_uploaded_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vbms_uploaded_documents_id_seq OWNED BY public.vbms_uploaded_documents.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id integer NOT NULL,
    created_at timestamp without time zone,
    event character varying NOT NULL,
    item_id integer NOT NULL,
    item_type character varying NOT NULL,
    object text,
    object_changes text,
    request_id uuid,
    whodunnit character varying
);


--
-- Name: COLUMN versions.request_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.versions.request_id IS 'The unique id of the request that caused this change';


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: veterans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.veterans (
    id bigint NOT NULL,
    closest_regional_office character varying,
    created_at timestamp without time zone,
    file_number character varying NOT NULL,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    name_suffix character varying,
    participant_id character varying,
    ssn character varying,
    updated_at timestamp without time zone
);


--
-- Name: COLUMN veterans.ssn; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.veterans.ssn IS 'The cached Social Security Number';


--
-- Name: veterans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.veterans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: veterans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.veterans_id_seq OWNED BY public.veterans.id;


--
-- Name: virtual_hearings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.virtual_hearings (
    id bigint NOT NULL,
    alias character varying,
    conference_deleted boolean DEFAULT false NOT NULL,
    conference_id integer,
    created_at timestamp without time zone NOT NULL,
    created_by_id bigint NOT NULL,
    guest_pin integer,
    hearing_id bigint,
    hearing_type character varying,
    host_pin integer,
    judge_email character varying,
    judge_email_sent boolean DEFAULT false NOT NULL,
    representative_email character varying,
    representative_email_sent boolean DEFAULT false NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    veteran_email character varying,
    veteran_email_sent boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN virtual_hearings.alias; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.alias IS 'Alias for conference in Pexip';


--
-- Name: COLUMN virtual_hearings.conference_deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.conference_deleted IS 'Whether or not the conference was deleted from Pexip';


--
-- Name: COLUMN virtual_hearings.conference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.conference_id IS 'ID of conference from Pexip';


--
-- Name: COLUMN virtual_hearings.created_by_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.created_by_id IS 'User who created the virtual hearing';


--
-- Name: COLUMN virtual_hearings.guest_pin; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.guest_pin IS 'PIN number for guests of Pexip conference';


--
-- Name: COLUMN virtual_hearings.hearing_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.hearing_id IS 'Associated hearing';


--
-- Name: COLUMN virtual_hearings.host_pin; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.host_pin IS 'PIN number for host of Pexip conference';


--
-- Name: COLUMN virtual_hearings.judge_email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.judge_email IS 'Judge''s email address';


--
-- Name: COLUMN virtual_hearings.judge_email_sent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.judge_email_sent IS 'Whether or not a notification email was sent to the judge';


--
-- Name: COLUMN virtual_hearings.representative_email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.representative_email IS 'Veteran''s representative''s email address';


--
-- Name: COLUMN virtual_hearings.representative_email_sent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.representative_email_sent IS 'Whether or not a notification email was sent to the veteran''s representative';


--
-- Name: COLUMN virtual_hearings.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.status IS 'The status of the Pexip conference';


--
-- Name: COLUMN virtual_hearings.veteran_email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.veteran_email IS 'Veteran''s email address';


--
-- Name: COLUMN virtual_hearings.veteran_email_sent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.virtual_hearings.veteran_email_sent IS 'Whether or not a notification email was sent to the veteran';


--
-- Name: virtual_hearings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.virtual_hearings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: virtual_hearings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.virtual_hearings_id_seq OWNED BY public.virtual_hearings.id;


--
-- Name: vso_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vso_configs (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    ihp_dockets character varying[],
    organization_id integer,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: vso_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vso_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vso_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vso_configs_id_seq OWNED BY public.vso_configs.id;


--
-- Name: worksheet_issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worksheet_issues (
    id integer NOT NULL,
    allow boolean DEFAULT false,
    appeal_id integer,
    created_at timestamp without time zone,
    deleted_at timestamp without time zone,
    deny boolean DEFAULT false,
    description character varying,
    dismiss boolean DEFAULT false,
    disposition character varying,
    from_vacols boolean,
    notes character varying,
    omo boolean DEFAULT false,
    remand boolean DEFAULT false,
    reopen boolean DEFAULT false,
    updated_at timestamp without time zone,
    vacols_sequence_id character varying
);


--
-- Name: worksheet_issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.worksheet_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worksheet_issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.worksheet_issues_id_seq OWNED BY public.worksheet_issues.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.advance_on_docket_motions ALTER COLUMN id SET DEFAULT nextval('public.advance_on_docket_motions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allocations ALTER COLUMN id SET DEFAULT nextval('public.allocations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotations ALTER COLUMN id SET DEFAULT nextval('public.annotations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN id SET DEFAULT nextval('public.api_keys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_views ALTER COLUMN id SET DEFAULT nextval('public.api_views_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appeal_series ALTER COLUMN id SET DEFAULT nextval('public.appeal_series_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appeal_views ALTER COLUMN id SET DEFAULT nextval('public.appeal_views_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appeals ALTER COLUMN id SET DEFAULT nextval('public.appeals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attorney_case_reviews ALTER COLUMN id SET DEFAULT nextval('public.attorney_case_reviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.available_hearing_locations ALTER COLUMN id SET DEFAULT nextval('public.available_hearing_locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.board_grant_effectuations ALTER COLUMN id SET DEFAULT nextval('public.board_grant_effectuations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_cancellations ALTER COLUMN id SET DEFAULT nextval('public.certification_cancellations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certifications ALTER COLUMN id SET DEFAULT nextval('public.certifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claim_establishments ALTER COLUMN id SET DEFAULT nextval('public.claim_establishments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claimants ALTER COLUMN id SET DEFAULT nextval('public.claimants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_folder_searches ALTER COLUMN id SET DEFAULT nextval('public.claims_folder_searches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decision_documents ALTER COLUMN id SET DEFAULT nextval('public.decision_documents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decision_issues ALTER COLUMN id SET DEFAULT nextval('public.decision_issues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_tasks ALTER COLUMN id SET DEFAULT nextval('public.dispatch_tasks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.distributed_cases ALTER COLUMN id SET DEFAULT nextval('public.distributed_cases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.distributions ALTER COLUMN id SET DEFAULT nextval('public.distributions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.docket_snapshots ALTER COLUMN id SET DEFAULT nextval('public.docket_snapshots_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.docket_tracers ALTER COLUMN id SET DEFAULT nextval('public.docket_tracers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_views ALTER COLUMN id SET DEFAULT nextval('public.document_views_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents ALTER COLUMN id SET DEFAULT nextval('public.documents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents_tags ALTER COLUMN id SET DEFAULT nextval('public.documents_tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.end_product_code_updates ALTER COLUMN id SET DEFAULT nextval('public.end_product_code_updates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.end_product_establishments ALTER COLUMN id SET DEFAULT nextval('public.end_product_establishments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form8s ALTER COLUMN id SET DEFAULT nextval('public.form8s_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.global_admin_logins ALTER COLUMN id SET DEFAULT nextval('public.global_admin_logins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_days ALTER COLUMN id SET DEFAULT nextval('public.hearing_days_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_issue_notes ALTER COLUMN id SET DEFAULT nextval('public.hearing_issue_notes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_locations ALTER COLUMN id SET DEFAULT nextval('public.hearing_locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_task_associations ALTER COLUMN id SET DEFAULT nextval('public.hearing_task_associations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_views ALTER COLUMN id SET DEFAULT nextval('public.hearing_views_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearings ALTER COLUMN id SET DEFAULT nextval('public.hearings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.higher_level_reviews ALTER COLUMN id SET DEFAULT nextval('public.higher_level_reviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intakes ALTER COLUMN id SET DEFAULT nextval('public.intakes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_notes ALTER COLUMN id SET DEFAULT nextval('public.job_notes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.judge_case_reviews ALTER COLUMN id SET DEFAULT nextval('public.judge_case_reviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.judge_team_roles ALTER COLUMN id SET DEFAULT nextval('public.judge_team_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_appeals ALTER COLUMN id SET DEFAULT nextval('public.legacy_appeals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_hearings ALTER COLUMN id SET DEFAULT nextval('public.legacy_hearings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_issue_optins ALTER COLUMN id SET DEFAULT nextval('public.legacy_issue_optins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.non_availabilities ALTER COLUMN id SET DEFAULT nextval('public.non_availabilities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations ALTER COLUMN id SET DEFAULT nextval('public.organizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations_users ALTER COLUMN id SET DEFAULT nextval('public.organizations_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people ALTER COLUMN id SET DEFAULT nextval('public.people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_decision_motions ALTER COLUMN id SET DEFAULT nextval('public.post_decision_motions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_closed_appeals ALTER COLUMN id SET DEFAULT nextval('public.ramp_closed_appeals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_election_rollbacks ALTER COLUMN id SET DEFAULT nextval('public.ramp_election_rollbacks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_elections ALTER COLUMN id SET DEFAULT nextval('public.ramp_elections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_issues ALTER COLUMN id SET DEFAULT nextval('public.ramp_issues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_refilings ALTER COLUMN id SET DEFAULT nextval('public.ramp_refilings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_synced_by_jobs ALTER COLUMN id SET DEFAULT nextval('public.record_synced_by_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remand_reasons ALTER COLUMN id SET DEFAULT nextval('public.remand_reasons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_decision_issues ALTER COLUMN id SET DEFAULT nextval('public.request_decision_issues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_issues ALTER COLUMN id SET DEFAULT nextval('public.request_issues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_issues_updates ALTER COLUMN id SET DEFAULT nextval('public.request_issues_updates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_periods ALTER COLUMN id SET DEFAULT nextval('public.schedule_periods_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.special_issue_lists ALTER COLUMN id SET DEFAULT nextval('public.special_issue_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplemental_claims ALTER COLUMN id SET DEFAULT nextval('public.supplemental_claims_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_timers ALTER COLUMN id SET DEFAULT nextval('public.task_timers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_quotas ALTER COLUMN id SET DEFAULT nextval('public.team_quotas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transcriptions ALTER COLUMN id SET DEFAULT nextval('public.transcriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_quotas ALTER COLUMN id SET DEFAULT nextval('public.user_quotas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vbms_uploaded_documents ALTER COLUMN id SET DEFAULT nextval('public.vbms_uploaded_documents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.veterans ALTER COLUMN id SET DEFAULT nextval('public.veterans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.virtual_hearings ALTER COLUMN id SET DEFAULT nextval('public.virtual_hearings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vso_configs ALTER COLUMN id SET DEFAULT nextval('public.vso_configs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worksheet_issues ALTER COLUMN id SET DEFAULT nextval('public.worksheet_issues_id_seq'::regclass);


--
-- Name: advance_on_docket_motions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.advance_on_docket_motions
    ADD CONSTRAINT advance_on_docket_motions_pkey PRIMARY KEY (id);


--
-- Name: allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allocations
    ADD CONSTRAINT allocations_pkey PRIMARY KEY (id);


--
-- Name: annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotations
    ADD CONSTRAINT annotations_pkey PRIMARY KEY (id);


--
-- Name: api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: api_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_views
    ADD CONSTRAINT api_views_pkey PRIMARY KEY (id);


--
-- Name: appeal_series_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appeal_series
    ADD CONSTRAINT appeal_series_pkey PRIMARY KEY (id);


--
-- Name: appeal_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appeal_views
    ADD CONSTRAINT appeal_views_pkey PRIMARY KEY (id);


--
-- Name: appeals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appeals
    ADD CONSTRAINT appeals_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: attorney_case_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attorney_case_reviews
    ADD CONSTRAINT attorney_case_reviews_pkey PRIMARY KEY (id);


--
-- Name: available_hearing_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.available_hearing_locations
    ADD CONSTRAINT available_hearing_locations_pkey PRIMARY KEY (id);


--
-- Name: board_grant_effectuations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.board_grant_effectuations
    ADD CONSTRAINT board_grant_effectuations_pkey PRIMARY KEY (id);


--
-- Name: certification_cancellations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certification_cancellations
    ADD CONSTRAINT certification_cancellations_pkey PRIMARY KEY (id);


--
-- Name: certifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certifications
    ADD CONSTRAINT certifications_pkey PRIMARY KEY (id);


--
-- Name: claim_establishments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claim_establishments
    ADD CONSTRAINT claim_establishments_pkey PRIMARY KEY (id);


--
-- Name: claimants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claimants
    ADD CONSTRAINT claimants_pkey PRIMARY KEY (id);


--
-- Name: claims_folder_searches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_folder_searches
    ADD CONSTRAINT claims_folder_searches_pkey PRIMARY KEY (id);


--
-- Name: decision_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decision_documents
    ADD CONSTRAINT decision_documents_pkey PRIMARY KEY (id);


--
-- Name: decision_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decision_issues
    ADD CONSTRAINT decision_issues_pkey PRIMARY KEY (id);


--
-- Name: dispatch_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_tasks
    ADD CONSTRAINT dispatch_tasks_pkey PRIMARY KEY (id);


--
-- Name: distributed_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.distributed_cases
    ADD CONSTRAINT distributed_cases_pkey PRIMARY KEY (id);


--
-- Name: distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.distributions
    ADD CONSTRAINT distributions_pkey PRIMARY KEY (id);


--
-- Name: docket_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.docket_snapshots
    ADD CONSTRAINT docket_snapshots_pkey PRIMARY KEY (id);


--
-- Name: docket_tracers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.docket_tracers
    ADD CONSTRAINT docket_tracers_pkey PRIMARY KEY (id);


--
-- Name: document_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_views
    ADD CONSTRAINT document_views_pkey PRIMARY KEY (id);


--
-- Name: documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: documents_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents_tags
    ADD CONSTRAINT documents_tags_pkey PRIMARY KEY (id);


--
-- Name: end_product_code_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.end_product_code_updates
    ADD CONSTRAINT end_product_code_updates_pkey PRIMARY KEY (id);


--
-- Name: end_product_establishments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.end_product_establishments
    ADD CONSTRAINT end_product_establishments_pkey PRIMARY KEY (id);


--
-- Name: form8s_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form8s
    ADD CONSTRAINT form8s_pkey PRIMARY KEY (id);


--
-- Name: global_admin_logins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.global_admin_logins
    ADD CONSTRAINT global_admin_logins_pkey PRIMARY KEY (id);


--
-- Name: hearing_days_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_days
    ADD CONSTRAINT hearing_days_pkey PRIMARY KEY (id);


--
-- Name: hearing_issue_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_issue_notes
    ADD CONSTRAINT hearing_issue_notes_pkey PRIMARY KEY (id);


--
-- Name: hearing_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_locations
    ADD CONSTRAINT hearing_locations_pkey PRIMARY KEY (id);


--
-- Name: hearing_task_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_task_associations
    ADD CONSTRAINT hearing_task_associations_pkey PRIMARY KEY (id);


--
-- Name: hearing_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_views
    ADD CONSTRAINT hearing_views_pkey PRIMARY KEY (id);


--
-- Name: hearings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearings
    ADD CONSTRAINT hearings_pkey PRIMARY KEY (id);


--
-- Name: higher_level_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.higher_level_reviews
    ADD CONSTRAINT higher_level_reviews_pkey PRIMARY KEY (id);


--
-- Name: intakes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intakes
    ADD CONSTRAINT intakes_pkey PRIMARY KEY (id);


--
-- Name: job_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_notes
    ADD CONSTRAINT job_notes_pkey PRIMARY KEY (id);


--
-- Name: judge_case_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.judge_case_reviews
    ADD CONSTRAINT judge_case_reviews_pkey PRIMARY KEY (id);


--
-- Name: judge_team_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.judge_team_roles
    ADD CONSTRAINT judge_team_roles_pkey PRIMARY KEY (id);


--
-- Name: legacy_appeals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_appeals
    ADD CONSTRAINT legacy_appeals_pkey PRIMARY KEY (id);


--
-- Name: legacy_hearings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_hearings
    ADD CONSTRAINT legacy_hearings_pkey PRIMARY KEY (id);


--
-- Name: legacy_issue_optins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_issue_optins
    ADD CONSTRAINT legacy_issue_optins_pkey PRIMARY KEY (id);


--
-- Name: messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: non_availabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.non_availabilities
    ADD CONSTRAINT non_availabilities_pkey PRIMARY KEY (id);


--
-- Name: organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: organizations_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations_users
    ADD CONSTRAINT organizations_users_pkey PRIMARY KEY (id);


--
-- Name: people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: post_decision_motions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_decision_motions
    ADD CONSTRAINT post_decision_motions_pkey PRIMARY KEY (id);


--
-- Name: ramp_closed_appeals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_closed_appeals
    ADD CONSTRAINT ramp_closed_appeals_pkey PRIMARY KEY (id);


--
-- Name: ramp_election_rollbacks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_election_rollbacks
    ADD CONSTRAINT ramp_election_rollbacks_pkey PRIMARY KEY (id);


--
-- Name: ramp_elections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_elections
    ADD CONSTRAINT ramp_elections_pkey PRIMARY KEY (id);


--
-- Name: ramp_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_issues
    ADD CONSTRAINT ramp_issues_pkey PRIMARY KEY (id);


--
-- Name: ramp_refilings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_refilings
    ADD CONSTRAINT ramp_refilings_pkey PRIMARY KEY (id);


--
-- Name: record_synced_by_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_synced_by_jobs
    ADD CONSTRAINT record_synced_by_jobs_pkey PRIMARY KEY (id);


--
-- Name: remand_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remand_reasons
    ADD CONSTRAINT remand_reasons_pkey PRIMARY KEY (id);


--
-- Name: request_decision_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_decision_issues
    ADD CONSTRAINT request_decision_issues_pkey PRIMARY KEY (id);


--
-- Name: request_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_issues
    ADD CONSTRAINT request_issues_pkey PRIMARY KEY (id);


--
-- Name: request_issues_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_issues_updates
    ADD CONSTRAINT request_issues_updates_pkey PRIMARY KEY (id);


--
-- Name: schedule_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_periods
    ADD CONSTRAINT schedule_periods_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: special_issue_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.special_issue_lists
    ADD CONSTRAINT special_issue_lists_pkey PRIMARY KEY (id);


--
-- Name: supplemental_claims_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplemental_claims
    ADD CONSTRAINT supplemental_claims_pkey PRIMARY KEY (id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: task_timers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_timers
    ADD CONSTRAINT task_timers_pkey PRIMARY KEY (id);


--
-- Name: tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: team_quotas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_quotas
    ADD CONSTRAINT team_quotas_pkey PRIMARY KEY (id);


--
-- Name: transcriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transcriptions
    ADD CONSTRAINT transcriptions_pkey PRIMARY KEY (id);


--
-- Name: user_quotas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_quotas
    ADD CONSTRAINT user_quotas_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vbms_uploaded_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vbms_uploaded_documents
    ADD CONSTRAINT vbms_uploaded_documents_pkey PRIMARY KEY (id);


--
-- Name: versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: veterans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.veterans
    ADD CONSTRAINT veterans_pkey PRIMARY KEY (id);


--
-- Name: virtual_hearings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.virtual_hearings
    ADD CONSTRAINT virtual_hearings_pkey PRIMARY KEY (id);


--
-- Name: vso_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vso_configs
    ADD CONSTRAINT vso_configs_pkey PRIMARY KEY (id);


--
-- Name: worksheet_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worksheet_issues
    ADD CONSTRAINT worksheet_issues_pkey PRIMARY KEY (id);


--
-- Name: decision_issues_uniq_by_disposition_and_ref_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX decision_issues_uniq_by_disposition_and_ref_id ON public.decision_issues USING btree (rating_issue_reference_id, disposition, participant_id);


--
-- Name: index_advance_on_docket_motions_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_advance_on_docket_motions_on_person_id ON public.advance_on_docket_motions USING btree (person_id);


--
-- Name: index_advance_on_docket_motions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_advance_on_docket_motions_on_user_id ON public.advance_on_docket_motions USING btree (user_id);


--
-- Name: index_allocations_on_schedule_period_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_allocations_on_schedule_period_id ON public.allocations USING btree (schedule_period_id);


--
-- Name: index_annotations_on_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_annotations_on_document_id ON public.annotations USING btree (document_id);


--
-- Name: index_annotations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_annotations_on_user_id ON public.annotations USING btree (user_id);


--
-- Name: index_api_keys_on_consumer_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_api_keys_on_consumer_name ON public.api_keys USING btree (consumer_name);


--
-- Name: index_api_keys_on_key_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_api_keys_on_key_digest ON public.api_keys USING btree (key_digest);


--
-- Name: index_appeal_views_on_appeal_type_and_appeal_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_appeal_views_on_appeal_type_and_appeal_id_and_user_id ON public.appeal_views USING btree (appeal_type, appeal_id, user_id);


--
-- Name: index_appeals_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appeals_on_uuid ON public.appeals USING btree (uuid);


--
-- Name: index_appeals_on_veteran_file_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appeals_on_veteran_file_number ON public.appeals USING btree (veteran_file_number);


--
-- Name: index_attorney_case_reviews_on_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attorney_case_reviews_on_task_id ON public.attorney_case_reviews USING btree (task_id);


--
-- Name: index_available_hearing_locations_on_appeal_id_and_appeal_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_available_hearing_locations_on_appeal_id_and_appeal_type ON public.available_hearing_locations USING btree (appeal_id, appeal_type);


--
-- Name: index_available_hearing_locations_on_veteran_file_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_available_hearing_locations_on_veteran_file_number ON public.available_hearing_locations USING btree (veteran_file_number);


--
-- Name: index_board_grant_effectuations_on_appeal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_board_grant_effectuations_on_appeal_id ON public.board_grant_effectuations USING btree (appeal_id);


--
-- Name: index_board_grant_effectuations_on_contention_reference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_board_grant_effectuations_on_contention_reference_id ON public.board_grant_effectuations USING btree (contention_reference_id);


--
-- Name: index_board_grant_effectuations_on_decision_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_board_grant_effectuations_on_decision_document_id ON public.board_grant_effectuations USING btree (decision_document_id);


--
-- Name: index_board_grant_effectuations_on_end_product_establishment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_board_grant_effectuations_on_end_product_establishment_id ON public.board_grant_effectuations USING btree (end_product_establishment_id);


--
-- Name: index_board_grant_effectuations_on_granted_decision_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_board_grant_effectuations_on_granted_decision_issue_id ON public.board_grant_effectuations USING btree (granted_decision_issue_id);


--
-- Name: index_cached_appeal_attributes_on_appeal_id_and_appeal_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cached_appeal_attributes_on_appeal_id_and_appeal_type ON public.cached_appeal_attributes USING btree (appeal_id, appeal_type);


--
-- Name: index_cached_appeal_attributes_on_vacols_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cached_appeal_attributes_on_vacols_id ON public.cached_appeal_attributes USING btree (vacols_id);


--
-- Name: index_cached_user_attributes_on_sdomainid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cached_user_attributes_on_sdomainid ON public.cached_user_attributes USING btree (sdomainid);


--
-- Name: index_certification_cancellations_on_certification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_certification_cancellations_on_certification_id ON public.certification_cancellations USING btree (certification_id);


--
-- Name: index_certifications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_certifications_on_user_id ON public.certifications USING btree (user_id);


--
-- Name: index_claimants_on_decision_review_type_and_decision_review_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claimants_on_decision_review_type_and_decision_review_id ON public.claimants USING btree (decision_review_type, decision_review_id);


--
-- Name: index_claimants_on_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claimants_on_participant_id ON public.claimants USING btree (participant_id);


--
-- Name: index_claims_folder_searches_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_folder_searches_on_user_id ON public.claims_folder_searches USING btree (user_id);


--
-- Name: index_decision_documents_on_appeal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_decision_documents_on_appeal_id ON public.decision_documents USING btree (appeal_id);


--
-- Name: index_decision_documents_on_citation_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_decision_documents_on_citation_number ON public.decision_documents USING btree (citation_number);


--
-- Name: index_decision_issues_on_decision_review_remanded; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_decision_issues_on_decision_review_remanded ON public.supplemental_claims USING btree (decision_review_remanded_type, decision_review_remanded_id);


--
-- Name: index_dispatch_tasks_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dispatch_tasks_on_user_id ON public.dispatch_tasks USING btree (user_id);


--
-- Name: index_distributed_cases_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_distributed_cases_on_case_id ON public.distributed_cases USING btree (case_id);


--
-- Name: index_docket_tracers_on_docket_snapshot_id_and_month; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_docket_tracers_on_docket_snapshot_id_and_month ON public.docket_tracers USING btree (docket_snapshot_id, month);


--
-- Name: index_document_views_on_document_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_document_views_on_document_id_and_user_id ON public.document_views USING btree (document_id, user_id);


--
-- Name: index_documents_on_file_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_file_number ON public.documents USING btree (file_number);


--
-- Name: index_documents_on_series_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_series_id ON public.documents USING btree (series_id);


--
-- Name: index_documents_on_vbms_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_documents_on_vbms_document_id ON public.documents USING btree (vbms_document_id);


--
-- Name: index_documents_tags_on_document_id_and_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_documents_tags_on_document_id_and_tag_id ON public.documents_tags USING btree (document_id, tag_id);


--
-- Name: index_end_product_code_updates_on_end_product_establishment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_end_product_code_updates_on_end_product_establishment_id ON public.end_product_code_updates USING btree (end_product_establishment_id);


--
-- Name: index_end_product_establishments_on_source_type_and_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_end_product_establishments_on_source_type_and_source_id ON public.end_product_establishments USING btree (source_type, source_id);


--
-- Name: index_end_product_establishments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_end_product_establishments_on_user_id ON public.end_product_establishments USING btree (user_id);


--
-- Name: index_end_product_establishments_on_veteran_file_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_end_product_establishments_on_veteran_file_number ON public.end_product_establishments USING btree (veteran_file_number);


--
-- Name: index_form8s_on_certification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_form8s_on_certification_id ON public.form8s USING btree (certification_id);


--
-- Name: index_hearing_appeal_stream_snapshots_hearing_and_appeal_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_hearing_appeal_stream_snapshots_hearing_and_appeal_ids ON public.hearing_appeal_stream_snapshots USING btree (hearing_id, appeal_id);


--
-- Name: index_hearing_days_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearing_days_on_created_by_id ON public.hearing_days USING btree (created_by_id);


--
-- Name: index_hearing_days_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearing_days_on_deleted_at ON public.hearing_days USING btree (deleted_at);


--
-- Name: index_hearing_days_on_updated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearing_days_on_updated_by_id ON public.hearing_days USING btree (updated_by_id);


--
-- Name: index_hearing_issue_notes_on_hearing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearing_issue_notes_on_hearing_id ON public.hearing_issue_notes USING btree (hearing_id);


--
-- Name: index_hearing_issue_notes_on_request_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearing_issue_notes_on_request_issue_id ON public.hearing_issue_notes USING btree (request_issue_id);


--
-- Name: index_hearing_locations_on_hearing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearing_locations_on_hearing_id ON public.hearing_locations USING btree (hearing_id);


--
-- Name: index_hearing_locations_on_hearing_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearing_locations_on_hearing_type ON public.hearing_locations USING btree (hearing_type);


--
-- Name: index_hearing_task_associations_on_hearing_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearing_task_associations_on_hearing_task_id ON public.hearing_task_associations USING btree (hearing_task_id);


--
-- Name: index_hearing_task_associations_on_hearing_type_and_hearing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearing_task_associations_on_hearing_type_and_hearing_id ON public.hearing_task_associations USING btree (hearing_type, hearing_id);


--
-- Name: index_hearing_views_on_hearing_id_and_user_id_and_hearing_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_hearing_views_on_hearing_id_and_user_id_and_hearing_type ON public.hearing_views USING btree (hearing_id, user_id, hearing_type);


--
-- Name: index_hearings_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearings_on_created_by_id ON public.hearings USING btree (created_by_id);


--
-- Name: index_hearings_on_updated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearings_on_updated_by_id ON public.hearings USING btree (updated_by_id);


--
-- Name: index_hearings_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hearings_on_uuid ON public.hearings USING btree (uuid);


--
-- Name: index_higher_level_reviews_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_higher_level_reviews_on_uuid ON public.higher_level_reviews USING btree (uuid);


--
-- Name: index_higher_level_reviews_on_veteran_file_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_higher_level_reviews_on_veteran_file_number ON public.higher_level_reviews USING btree (veteran_file_number);


--
-- Name: index_intakes_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intakes_on_type ON public.intakes USING btree (type);


--
-- Name: index_intakes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intakes_on_user_id ON public.intakes USING btree (user_id);


--
-- Name: index_intakes_on_veteran_file_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intakes_on_veteran_file_number ON public.intakes USING btree (veteran_file_number);


--
-- Name: index_job_notes_on_job_type_and_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_job_notes_on_job_type_and_job_id ON public.job_notes USING btree (job_type, job_id);


--
-- Name: index_job_notes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_job_notes_on_user_id ON public.job_notes USING btree (user_id);


--
-- Name: index_judge_team_roles_on_organizations_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_judge_team_roles_on_organizations_user_id ON public.judge_team_roles USING btree (organizations_user_id);


--
-- Name: index_legacy_appeals_on_appeal_series_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_appeals_on_appeal_series_id ON public.legacy_appeals USING btree (appeal_series_id);


--
-- Name: index_legacy_appeals_on_vacols_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_legacy_appeals_on_vacols_id ON public.legacy_appeals USING btree (vacols_id);


--
-- Name: index_legacy_hearings_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_hearings_on_created_by_id ON public.legacy_hearings USING btree (created_by_id);


--
-- Name: index_legacy_hearings_on_hearing_day_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_hearings_on_hearing_day_id ON public.legacy_hearings USING btree (hearing_day_id);


--
-- Name: index_legacy_hearings_on_updated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_hearings_on_updated_by_id ON public.legacy_hearings USING btree (updated_by_id);


--
-- Name: index_legacy_hearings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_hearings_on_user_id ON public.legacy_hearings USING btree (user_id);


--
-- Name: index_legacy_hearings_on_vacols_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_legacy_hearings_on_vacols_id ON public.legacy_hearings USING btree (vacols_id);


--
-- Name: index_legacy_issue_optins_on_request_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_issue_optins_on_request_issue_id ON public.legacy_issue_optins USING btree (request_issue_id);


--
-- Name: index_messages_on_detail_type_and_detail_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_detail_type_and_detail_id ON public.messages USING btree (detail_type, detail_id);


--
-- Name: index_non_availabilities_on_schedule_period_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_non_availabilities_on_schedule_period_id ON public.non_availabilities USING btree (schedule_period_id);


--
-- Name: index_on_request_issue_id_and_decision_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_on_request_issue_id_and_decision_issue_id ON public.request_decision_issues USING btree (request_issue_id, decision_issue_id);


--
-- Name: index_organizations_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on_url ON public.organizations USING btree (url);


--
-- Name: index_organizations_users_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organizations_users_on_organization_id ON public.organizations_users USING btree (organization_id);


--
-- Name: index_organizations_users_on_user_id_and_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_users_on_user_id_and_organization_id ON public.organizations_users USING btree (user_id, organization_id);


--
-- Name: index_people_on_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_people_on_participant_id ON public.people USING btree (participant_id);


--
-- Name: index_post_decision_motions_on_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_decision_motions_on_task_id ON public.post_decision_motions USING btree (task_id);


--
-- Name: index_ramp_election_rollbacks_on_ramp_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ramp_election_rollbacks_on_ramp_election_id ON public.ramp_election_rollbacks USING btree (ramp_election_id);


--
-- Name: index_ramp_election_rollbacks_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ramp_election_rollbacks_on_user_id ON public.ramp_election_rollbacks USING btree (user_id);


--
-- Name: index_ramp_elections_on_veteran_file_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ramp_elections_on_veteran_file_number ON public.ramp_elections USING btree (veteran_file_number);


--
-- Name: index_ramp_issues_on_review_type_and_review_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ramp_issues_on_review_type_and_review_id ON public.ramp_issues USING btree (review_type, review_id);


--
-- Name: index_ramp_refilings_on_veteran_file_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ramp_refilings_on_veteran_file_number ON public.ramp_refilings USING btree (veteran_file_number);


--
-- Name: index_record_synced_by_jobs_on_record_type_and_record_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_record_synced_by_jobs_on_record_type_and_record_id ON public.record_synced_by_jobs USING btree (record_type, record_id);


--
-- Name: index_remand_reasons_on_decision_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_remand_reasons_on_decision_issue_id ON public.remand_reasons USING btree (decision_issue_id);


--
-- Name: index_request_issues_on_contention_reference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_request_issues_on_contention_reference_id ON public.request_issues USING btree (contention_reference_id);


--
-- Name: index_request_issues_on_contested_decision_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_issues_on_contested_decision_issue_id ON public.request_issues USING btree (contested_decision_issue_id);


--
-- Name: index_request_issues_on_contested_rating_issue_reference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_issues_on_contested_rating_issue_reference_id ON public.request_issues USING btree (contested_rating_issue_reference_id);


--
-- Name: index_request_issues_on_decision_review_columns; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_issues_on_decision_review_columns ON public.request_issues USING btree (decision_review_type, decision_review_id);


--
-- Name: index_request_issues_on_end_product_establishment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_issues_on_end_product_establishment_id ON public.request_issues USING btree (end_product_establishment_id);


--
-- Name: index_request_issues_on_ineligible_due_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_issues_on_ineligible_due_to_id ON public.request_issues USING btree (ineligible_due_to_id);


--
-- Name: index_request_issues_updates_on_review_type_and_review_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_issues_updates_on_review_type_and_review_id ON public.request_issues_updates USING btree (review_type, review_id);


--
-- Name: index_request_issues_updates_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_issues_updates_on_user_id ON public.request_issues_updates USING btree (user_id);


--
-- Name: index_schedule_periods_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_schedule_periods_on_user_id ON public.schedule_periods USING btree (user_id);


--
-- Name: index_special_issue_lists_on_appeal_type_and_appeal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_special_issue_lists_on_appeal_type_and_appeal_id ON public.special_issue_lists USING btree (appeal_type, appeal_id);


--
-- Name: index_supplemental_claims_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supplemental_claims_on_uuid ON public.supplemental_claims USING btree (uuid);


--
-- Name: index_supplemental_claims_on_veteran_file_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supplemental_claims_on_veteran_file_number ON public.supplemental_claims USING btree (veteran_file_number);


--
-- Name: index_tags_on_text; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_text ON public.tags USING btree (text);


--
-- Name: index_task_timers_on_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_task_timers_on_task_id ON public.task_timers USING btree (task_id);


--
-- Name: index_tasks_on_appeal_type_and_appeal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_appeal_type_and_appeal_id ON public.tasks USING btree (appeal_type, appeal_id);


--
-- Name: index_tasks_on_assigned_to_type_and_assigned_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_assigned_to_type_and_assigned_to_id ON public.tasks USING btree (assigned_to_type, assigned_to_id);


--
-- Name: index_tasks_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_parent_id ON public.tasks USING btree (parent_id);


--
-- Name: index_tasks_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_status ON public.tasks USING btree (status);


--
-- Name: index_tasks_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_type ON public.tasks USING btree (type);


--
-- Name: index_team_quotas_on_date_and_task_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_quotas_on_date_and_task_type ON public.team_quotas USING btree (date, task_type);


--
-- Name: index_transcriptions_on_hearing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transcriptions_on_hearing_id ON public.transcriptions USING btree (hearing_id);


--
-- Name: index_user_quotas_on_team_quota_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_quotas_on_team_quota_id_and_user_id ON public.user_quotas USING btree (team_quota_id, user_id);


--
-- Name: index_users_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_status ON public.users USING btree (status);


--
-- Name: index_users_unique_css_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_unique_css_id ON public.users USING btree (upper((css_id)::text));


--
-- Name: index_vbms_uploaded_documents_on_appeal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vbms_uploaded_documents_on_appeal_id ON public.vbms_uploaded_documents USING btree (appeal_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_versions_on_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_request_id ON public.versions USING btree (request_id);


--
-- Name: index_veterans_on_file_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_veterans_on_file_number ON public.veterans USING btree (file_number);


--
-- Name: index_veterans_on_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_veterans_on_participant_id ON public.veterans USING btree (participant_id);


--
-- Name: index_veterans_on_ssn; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_veterans_on_ssn ON public.veterans USING btree (ssn);


--
-- Name: index_virtual_hearings_on_alias; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_virtual_hearings_on_alias ON public.virtual_hearings USING btree (alias);


--
-- Name: index_virtual_hearings_on_conference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_virtual_hearings_on_conference_id ON public.virtual_hearings USING btree (conference_id);


--
-- Name: index_virtual_hearings_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_virtual_hearings_on_created_by_id ON public.virtual_hearings USING btree (created_by_id);


--
-- Name: index_virtual_hearings_on_hearing_type_and_hearing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_virtual_hearings_on_hearing_type_and_hearing_id ON public.virtual_hearings USING btree (hearing_type, hearing_id);


--
-- Name: index_vso_configs_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vso_configs_on_organization_id ON public.vso_configs USING btree (organization_id);


--
-- Name: index_worksheet_issues_on_appeal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worksheet_issues_on_appeal_id ON public.worksheet_issues USING btree (appeal_id);


--
-- Name: index_worksheet_issues_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worksheet_issues_on_deleted_at ON public.worksheet_issues USING btree (deleted_at);


--
-- Name: unique_index_to_avoid_duplicate_intakes; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_index_to_avoid_duplicate_intakes ON public.intakes USING btree (type, veteran_file_number) WHERE (completed_at IS NULL);


--
-- Name: unique_index_to_avoid_multiple_intakes; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_index_to_avoid_multiple_intakes ON public.intakes USING btree (user_id) WHERE (completed_at IS NULL);


--
-- Name: fk_rails_0a986af930; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_decision_motions
    ADD CONSTRAINT fk_rails_0a986af930 FOREIGN KEY (task_id) REFERENCES public.tasks(id);


--
-- Name: fk_rails_0eb8e688f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appeal_views
    ADD CONSTRAINT fk_rails_0eb8e688f0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_1c39b6a84c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_hearings
    ADD CONSTRAINT fk_rails_1c39b6a84c FOREIGN KEY (updated_by_id) REFERENCES public.users(id);


--
-- Name: fk_rails_23c12f1a27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_views
    ADD CONSTRAINT fk_rails_23c12f1a27 FOREIGN KEY (api_key_id) REFERENCES public.api_keys(id);


--
-- Name: fk_rails_2def940b2d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_appeals
    ADD CONSTRAINT fk_rails_2def940b2d FOREIGN KEY (appeal_series_id) REFERENCES public.appeal_series(id);


--
-- Name: fk_rails_3ae148fe3b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_quotas
    ADD CONSTRAINT fk_rails_3ae148fe3b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_3b6a920e3b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.end_product_establishments
    ADD CONSTRAINT fk_rails_3b6a920e3b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_3ee6dc1617; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_hearings
    ADD CONSTRAINT fk_rails_3ee6dc1617 FOREIGN KEY (hearing_day_id) REFERENCES public.hearing_days(id);


--
-- Name: fk_rails_4043df79bf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annotations
    ADD CONSTRAINT fk_rails_4043df79bf FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_408764afe8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_issues_updates
    ADD CONSTRAINT fk_rails_408764afe8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_4998bbb1b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_views
    ADD CONSTRAINT fk_rails_4998bbb1b0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_4e80f1285a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_periods
    ADD CONSTRAINT fk_rails_4e80f1285a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_5601279132; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intakes
    ADD CONSTRAINT fk_rails_5601279132 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_5f8536cc83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_hearings
    ADD CONSTRAINT fk_rails_5f8536cc83 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_6876977395; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearings
    ADD CONSTRAINT fk_rails_6876977395 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: fk_rails_8cfc7a63ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_days
    ADD CONSTRAINT fk_rails_8cfc7a63ed FOREIGN KEY (updated_by_id) REFERENCES public.users(id);


--
-- Name: fk_rails_9573b3db7e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.advance_on_docket_motions
    ADD CONSTRAINT fk_rails_9573b3db7e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_99ad041748; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.certifications
    ADD CONSTRAINT fk_rails_99ad041748 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_9b565dc0d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearings
    ADD CONSTRAINT fk_rails_9b565dc0d0 FOREIGN KEY (updated_by_id) REFERENCES public.users(id);


--
-- Name: fk_rails_a4855043ec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_views
    ADD CONSTRAINT fk_rails_a4855043ec FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_a89915da94; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations_users
    ADD CONSTRAINT fk_rails_a89915da94 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_c173738cd6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_election_rollbacks
    ADD CONSTRAINT fk_rails_c173738cd6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_d2dc5ed04b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ramp_closed_appeals
    ADD CONSTRAINT fk_rails_d2dc5ed04b FOREIGN KEY (ramp_election_id) REFERENCES public.ramp_elections(id);


--
-- Name: fk_rails_e5f06ac1fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_tasks
    ADD CONSTRAINT fk_rails_e5f06ac1fc FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_e7c371c9ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hearing_days
    ADD CONSTRAINT fk_rails_e7c371c9ac FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: fk_rails_ef04ca8e14; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_hearings
    ADD CONSTRAINT fk_rails_ef04ca8e14 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: fk_rails_fc7d5f13d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_folder_searches
    ADD CONSTRAINT fk_rails_fc7d5f13d2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20160912142431'),
('20161031155400'),
('20161031274815'),
('20161102170128'),
('20161109182923'),
('20161115191744'),
('20161121140139'),
('20161122221255'),
('20161212154649'),
('20161212185240'),
('20161213140745'),
('20161220190026'),
('20170106141818'),
('20170117194115'),
('20170124205843'),
('20170127155914'),
('20170127165539'),
('20170130163058'),
('20170201183126'),
('20170206152319'),
('20170206153412'),
('20170215190838'),
('20170217164117'),
('20170228191800'),
('20170309203602'),
('20170311235000'),
('20170320195443'),
('20170321213240'),
('20170321214122'),
('20170324120538'),
('20170411202724'),
('20170413191800'),
('20170414183652'),
('20170424151347'),
('20170427190104'),
('20170427191501'),
('20170427194351'),
('20170427201655'),
('20170502144719'),
('20170502213808'),
('20170502222054'),
('20170503153606'),
('20170508161151'),
('20170509155046'),
('20170509175505'),
('20170510131954'),
('20170511155922'),
('20170511211242'),
('20170517141505'),
('20170522132232'),
('20170522214928'),
('20170525191011'),
('20170530202048'),
('20170602152033'),
('20170602182637'),
('20170615162530'),
('20170619154525'),
('20170713163404'),
('20170724162126'),
('20170810193012'),
('20170814194102'),
('20170815120508'),
('20170906191428'),
('20170915195705'),
('20170918151745'),
('20170921154613'),
('20170921164906'),
('20170921182723'),
('20170929181348'),
('20170929182028'),
('20171005184047'),
('20171005184519'),
('20171012210658'),
('20171013213546'),
('20171031171026'),
('20171031192541'),
('20171101191123'),
('20171101191249'),
('20171101214530'),
('20171103215233'),
('20171106153924'),
('20171206003916'),
('20171206004956'),
('20171206005110'),
('20171207014603'),
('20171212231913'),
('20171218163226'),
('20171219182001'),
('20171219182526'),
('20171226172852'),
('20171230164910'),
('20180103203812'),
('20180103204311'),
('20180103205014'),
('20180104163740'),
('20180104213048'),
('20180105192532'),
('20180105193204'),
('20180108202645'),
('20180110165318'),
('20180112184032'),
('20180112215821'),
('20180112220428'),
('20180118152832'),
('20180118194440'),
('20180123190138'),
('20180123190139'),
('20180123190140'),
('20180123190141'),
('20180123190443'),
('20180126175818'),
('20180205142339'),
('20180205183203'),
('20180220210915'),
('20180221163923'),
('20180226182335'),
('20180226201744'),
('20180227221713'),
('20180306144550'),
('20180320221924'),
('20180321153005'),
('20180326153826'),
('20180327211711'),
('20180328182747'),
('20180328220242'),
('20180402204041'),
('20180402231703'),
('20180411152656'),
('20180416184214'),
('20180418224851'),
('20180428135137'),
('20180430210552'),
('20180504231033'),
('20180507224351'),
('20180507232459'),
('20180508192057'),
('20180508195838'),
('20180508221045'),
('20180510171815'),
('20180514160004'),
('20180516213251'),
('20180517174411'),
('20180517183111'),
('20180517204250'),
('20180517204321'),
('20180523170734'),
('20180523171432'),
('20180524000759'),
('20180524173201'),
('20180524174054'),
('20180525153724'),
('20180529171733'),
('20180529214648'),
('20180530210916'),
('20180531181503'),
('20180601173719'),
('20180606222704'),
('20180607184059'),
('20180626151744'),
('20180626151805'),
('20180626151823'),
('20180626152943'),
('20180626154654'),
('20180626154709'),
('20180626215321'),
('20180627150431'),
('20180628195002'),
('20180703225343'),
('20180705173803'),
('20180706224911'),
('20180710144303'),
('20180710180018'),
('20180710214914'),
('20180717185230'),
('20180719153039'),
('20180719153446'),
('20180724145953'),
('20180803183202'),
('20180806124145'),
('20180806210221'),
('20180808215503'),
('20180817195432'),
('20180824172906'),
('20180824223530'),
('20180824224113'),
('20180827194153'),
('20180831162601'),
('20180905163350'),
('20180905214036'),
('20180907003818'),
('20180907184617'),
('20180910195448'),
('20180911203611'),
('20180911205053'),
('20180912142310'),
('20180912224413'),
('20180913171645'),
('20180914201526'),
('20180919144814'),
('20180919213618'),
('20180921145533'),
('20180921174854'),
('20180924131352'),
('20180925223942'),
('20180926132244'),
('20180926143801'),
('20180926182000'),
('20180927004213'),
('20180927173613'),
('20180928211349'),
('20181001133041'),
('20181001214125'),
('20181004221403'),
('20181004232948'),
('20181009214213'),
('20181010185251'),
('20181010220548'),
('20181012204811'),
('20181016155752'),
('20181018143032'),
('20181018191048'),
('20181023145207'),
('20181023145350'),
('20181023172507'),
('20181023204155'),
('20181025162415'),
('20181025214440'),
('20181029145607'),
('20181030123030'),
('20181031183351'),
('20181031194415'),
('20181101193212'),
('20181102142804'),
('20181102143237'),
('20181106010604'),
('20181107163119'),
('20181107182512'),
('20181107185230'),
('20181107225536'),
('20181109131525'),
('20181113205510'),
('20181114142531'),
('20181116155733'),
('20181119180633'),
('20181119181014'),
('20181119212851'),
('20181119233040'),
('20181122005245'),
('20181123182557'),
('20181123211515'),
('20181126190223'),
('20181127201444'),
('20181128225613'),
('20181129224312'),
('20181129224817'),
('20181129230649'),
('20181130224517'),
('20181203174849'),
('20181203195219'),
('20181203223308'),
('20181203231527'),
('20181205201428'),
('20181206130120'),
('20181211201506'),
('20181212150819'),
('20181213191137'),
('20181214003212'),
('20181217195658'),
('20181218173534'),
('20181218214242'),
('20181218214725'),
('20181219005124'),
('20181219153145'),
('20181219175338'),
('20181221151935'),
('20181221164327'),
('20181224142346'),
('20181224183228'),
('20181228182233'),
('20190102201419'),
('20190103175308'),
('20190103200519'),
('20190104163907'),
('20190104170322'),
('20190104182112'),
('20190104190600'),
('20190107161740'),
('20190107184216'),
('20190107210543'),
('20190109234311'),
('20190110162001'),
('20190110220936'),
('20190111000717'),
('20190113170514'),
('20190114225909'),
('20190115170256'),
('20190117054954'),
('20190117151019'),
('20190117232830'),
('20190118155859'),
('20190122230514'),
('20190125151257'),
('20190125223733'),
('20190128185846'),
('20190129002938'),
('20190129232540'),
('20190129233527'),
('20190129233723'),
('20190131012932'),
('20190205195304'),
('20190205201919'),
('20190206165710'),
('20190207182603'),
('20190208191441'),
('20190211161214'),
('20190211161507'),
('20190211164106'),
('20190212142949'),
('20190214214208'),
('20190215145907'),
('20190215194659'),
('20190219143859'),
('20190220014413'),
('20190220200720'),
('20190220201237'),
('20190220225538'),
('20190221004127'),
('20190221205756'),
('20190222185303'),
('20190222185310'),
('20190222224704'),
('20190227002146'),
('20190227003709'),
('20190228004408'),
('20190228185229'),
('20190301001506'),
('20190301233254'),
('20190302000509'),
('20190302004820'),
('20190306224527'),
('20190307210920'),
('20190312154538'),
('20190312160930'),
('20190313152622'),
('20190319144125'),
('20190319171122'),
('20190320140634'),
('20190320173238'),
('20190320215814'),
('20190321204810'),
('20190322203141'),
('20190322210359'),
('20190322235314'),
('20190323003906'),
('20190325152148'),
('20190326200140'),
('20190326202730'),
('20190328163217'),
('20190329163603'),
('20190329211019'),
('20190401192800'),
('20190402190112'),
('20190402192428'),
('20190402195026'),
('20190402195624'),
('20190409231234'),
('20190410235934'),
('20190411010006'),
('20190411161143'),
('20190412182006'),
('20190412184430'),
('20190412214706'),
('20190430151227'),
('20190430152338'),
('20190430225016'),
('20190503191516'),
('20190509155449'),
('20190520201631'),
('20190529143622'),
('20190530185719'),
('20190531152758'),
('20190603150958'),
('20190605211054'),
('20190605212511'),
('20190617152134'),
('20190617164845'),
('20190618173816'),
('20190628181403'),
('20190701170815'),
('20190702171142'),
('20190705172439'),
('20190711152558'),
('20190711181657'),
('20190711191432'),
('20190711194030'),
('20190716211829'),
('20190718004714'),
('20190718221953'),
('20190718223313'),
('20190724190057'),
('20190724193340'),
('20190724200447'),
('20190724201133'),
('20190730193421'),
('20190806133551'),
('20190806180125'),
('20190807144959'),
('20190807192535'),
('20190807203232'),
('20190815125313'),
('20190816145951'),
('20190816194620'),
('20190816210203'),
('20190820083623'),
('20190821162943'),
('20190821180128'),
('20190827142452'),
('20190829183634'),
('20190917210301'),
('20190920213522'),
('20190924110338'),
('20190925205112'),
('20191001224339'),
('20191010164748'),
('20191010195542'),
('20191015204516'),
('20191017235707'),
('20191021215017'),
('20191023204446'),
('20191028200741'),
('20191031203544'),
('20191031211321'),
('20191101145935'),
('20191106153923');


