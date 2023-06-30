# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute('CREATE TABLE IF NOT EXISTS public.vbms_ext_claim (
            "CLAIM_ID" numeric(38,0) primary key unique NOT null,
            "CLAIM_DATE" timestamp without time zone,
            "EP_CODE" character varying(25),
            "SUSPENSE_DATE" timestamp without time zone,
            "SUSPENSE_REASON_CODE" character varying(25),
            "SUSPENSE_REASON_COMMENTS" character varying(1000),
            "CLAIMANT_PERSON_ID" numeric(38,0),
            "CONTENTION_COUNT" integer,
            "CLAIM_SOJ" character varying(25),
            "TEMPORARY_CLAIM_SOJ" character varying(25),
            "PRIORITY" character varying(10),
            "TYPE_CODE" character varying(25),
            "LIFECYCLE_STATUS_NAME" character varying(50),
            "LEVEL_STATUS_CODE" character varying(25),
            "SUBMITTER_APPLICATION_CODE" character varying(25),
            "SUBMITTER_ROLE_CODE" character varying(25),
            "VETERAN_PERSON_ID" numeric(15,0),
            "ESTABLISHMENT_DATE" timestamp without time zone,
            "INTAKE_SITE" character varying(25),
            "PAYEE_CODE" character varying(25),
            "SYNC_ID" numeric(38,0) NOT null,
            "CREATEDDT" timestamp without time zone NOT null default NULL,
            "LASTUPDATEDT" timestamp without time zone NOT null default NULL,
            "EXPIRATIONDT" timestamp without time zone,
            "VERSION" numeric(38,0) NOT null default NULL,
            "LIFECYCLE_STATUS_CHANGE_DATE" timestamp without time zone,
            "RATING_SOJ" character varying(25),
            "PROGRAM_TYPE_CODE" character varying(10),
            "SERVICE_TYPE_CODE" character varying(10),
            "PREVENT_AUDIT_TRIG" smallint NOT null default 0,
            "PRE_DISCHARGE_TYPE_CODE" character varying(10),
            "PRE_DISCHARGE_IND" character varying(5),
            "ORGANIZATION_NAME" character varying(100),
            "ORGANIZATION_SOJ" character varying(25),
            "ALLOW_POA_ACCESS" character varying(5),
            "POA_CODE" character varying(25)
          );')

conn.execute('CREATE INDEX claim_id_index ON public.vbms_ext_claim ("CLAIM_ID")')
conn.execute('CREATE INDEX claim_id_index ON public.vbms_ext_claim ("LEVEL_STATUS_CODE")')
conn.close
