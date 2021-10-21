---
title: VACOLS Schema
tags: "vacols"
weight: 31
---
# VACOLS Schema

## VACOLS - VBMS Mapping

- CORRES table contains most of Veteran's info (should match VBMS)
- TIVBMS field allows us to determine if the claim is ready for VBMS
- TIOCTIME of no greater than 3 days ago will let us pull that specific Full Grant (no time limit on Partial/Remands)
- BRIEFF.BFREGOFF and BFCURLOC, PRIORLOC.LOCDIN and LOCDOUT, ASSIGN.TSKRQACT will be updated by Dispatch must be validated

## Table Joins

{{< details "Table joins" >}}
| TABLE  | TABLE | JOIN ON |
| -------- | -------- | -------- |
| Brieff | Corres | bfcorkey = stafkey |
| Folder | Corres | ticorkey = stafkey |
| Brieff | Folder | bfkey = ticknum |
| Brieff | Attach | bfkey = imgtkky |
| Brieff | Assign | bfkey = tsktknum |
| Brieff | Mail | bfkey = mlfolder |
| Brieff | Cova | bfkey = cvfolder |
| Brieff | PriorLoc | bfkey = lockey |
| Brieff | Issues | bfkey = isskey |
| Brieff | Hearsched | bfkey = folder_nr |
| Brieff | Decass | bfkey = defolder |
| Brieff | Othdocs | bfkey = ticknum |
| Staff | Employee | stafkey = login_id |
| Issues | Rmdrea | isskey = rmdkey |
| Issues | Rmdrea | issseq = rmdissseq |
{{< /details >}}

Also check out [visualization of table relationships](https://dbdiagram.io/d/5f8225973a78976d7b77234f).

<div class="vacolsTables">

## Main Tables

### ASSIGN (Diary)
Notes about the claim

{{< details "ASSIGN table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Unique Primary Key Field|TASKNUM|VARCHAR2|12|
Folder Related To|TSKTKNM|VARCHAR2|12|Attach(imgtkky), Brieff(bfkey), Folder(ticknum), Hearsched(folder\_nr), Priorloc(lockey)
Staff Member Assigned to Perform Work|TSKSTFAS|VARCHAR2|16|Staff(stafkey)
Diary Indicator|TSKACTCD|VARCHAR2|10|
Classification of Assignment|TSKCLASS|VARCHAR2|10|
Requested Activity|TSKRQACT|VARCHAR2|280|
Response Notes|TSKRSPN|VARCHAR2|200|
Date Assigned|TSKDASSN|DATE| |
Days to Complete|TSKDTC|NUMBER|22|
Diary Due Date|TSKDDUE|DATE| |
Date Closed|TSKDCLS|DATE| |
Owner of Assignment - Usually Creator|TSKSTOWN|VARCHAR2|16|
Diary Status (Pending, Closed)|TSKSTAT|VARCHAR2|1|
Not Used|TSKOWNTS|VARCHAR2|12|
Not Used|TSKCLSTM|DATE| |
Added by|TSKADUSR|VARCHAR2|16|Staff(stafkey)
Date/Time Record was Added|TSKADTM|DATE| |
Last Modified By|TSKMDUSR|VARCHAR2|16|Staff(stafkey)
Date/Time Record was Last Modified|TSKMDTM|DATE| |
Not Used|TSACTIVE|VARCHAR2|1|
Specialty (for IME, VHA, or AFIP)|TSSPARE1|VARCHAR2|30|
Not Used|TSSPARE2|VARCHAR2|30|
Not Used|TSSPARE3|VARCHAR2|30|
Not Used|TSREAD1|VARCHAR2|28|
VISN|TSREAD|VARCHAR2|16|
Not Used|TSKORDER|VARCHAR2|15|
Not Used|TSSYS|VARCHAR2|16|
{{< /details >}}

### ATTACH (Attachments)

{{< details "ATTACH table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Unique Primary Key Field|IMGKEY|VARCHAR2|12|
Folder Related To|IMGTKKY|VARCHAR2|12|Assign(tsktknm), Brieff(bfkey), Folder(ticknum), Hearsched(folder\_nr), Priorloc(lockey)
Not Used|IMGTSKKY|VARCHAR2|12|
Full Path to Attached File|IMGDOC|VARCHAR2|96|
Attachment Type|IMGDOCTP|VARCHAR2|4|
Description/Comments|IMGDESC|VARCHAR2|70|
Original Location of File or Application Element|IMGLOC|VARCHAR2|150|
Classification of The Attachment|IMGCLASS|VARCHAR2|10|
Staff Member Designated Responsible for This Item|IMGOWNER|VARCHAR2|16|Staff(stafkey)
User Who Added Attachment|IMGADUSR|VARCHAR2|16|Staff(stafkey)
Date The Attachment was Added|IMGADTM|DATE| |
User Who Last Modified Attachment|IMGMDUSR|VARCHAR2|16|Staff(stafkey)
Date The Attachment was Last Modified|IMGMDTM|DATE| |
Active/Inactive Flag|IMACTIVE|VARCHAR2|1|
Mailed to Address line 1|IMSPARE1|VARCHAR2|30|
Mailed to Address line 2|IMSPARE2|VARCHAR2|30|
Mailed to City, State and Zip|IMREAD1|VARCHAR2|28|
Not Used|IMREAD2|VARCHAR2|16|
Not Used|IMGSYS|VARCHAR2|16|
{{< /details >}}

### BRIEFF (Briefface)
Appeal Info, multiple per Vet): 3.5+ million legacy appeals
- BFDEC - Decision date (just visual, but make it equals TIOCTIME)
  * Appeal Status:  BFMPRO, 3 chars
    * [Stats for Legacy Appeal status](https://github.com/department-of-veterans-affairs/caseflow/issues/13254#issuecomment-581648391)
    * [Status code definitions](https://github.com/department-of-veterans-affairs/VACOLS/blob/master/docs/VACOLS%20Reference%20Docs/VACOLS.System.Codes.doc)
    * ACT: ACTIVE (Case currently at BVA)
    * ADV: ADVANCE (NOD Filed. Case currently at RO)
    * REM: REMAND (Case has been Remanded to RO or AMC)
    * HIS: HISTORY (BVA action is complete)
    * MOT: MOTION (appellant has filed a motion for reconsideration)
  * From Caseflow: [case.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/vacols/case.rb)
- BFDC - Disposition of Appeal; see `VACOLS.System.Codes.doc` at [VACOLS Reference Docs](https://github.com/department-of-veterans-affairs/VACOLS/tree/master/docs/VACOLS%20Reference%20Docs) for Disposition Codes
  * 1: Allowed
  * 3: Remanded
  * 4: Denied
  * 5: Vacated
  * 6: Dismissed, Other
  * 8: Dismissed, Death
  * 9: Withdrawn
  * D: Designation of Record
  * M: Merged Appeal
  * R: Reconsideration by Letter
  * Above are codes for "BVA Disposition". There are other disposition codes that refer to "Field Disposition"

{{< details "BRIEFF table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Folder Number (Unique Primary Key)|BFKEY|VARCHAR2|12|Assign(tsktknm), Attach(imgtkky), Folder(ticknum), Hearsched(folder_nr), Priorloc(lockey), Issue(Isskey)|Appeal ID
Date/Time of Decision|BFDDEC|DATE| |
Corres Table Key|BFCORKEY|VARCHAR2|16|Corres (stafkey)
Appellant ID (SSN or Claim Number)|BFCORLID|VARCHAR2|16||Veteran ID, SSN (VBMS ID)
Stays Indicator (CUE, Tobacco, IVM)|BFDCN|VARCHAR2|6|
Video Hearing Requested Indicator|BFDOCIND|VARCHAR2|1|
Insurance/Loan Number|BFPDNUM|VARCHAR2|12|
Date/Time of Prior Decision|BFDPDCN|DATE| |
Sub-location - Home , Shelf loc, VSO employee|BFORGTIC|VARCHAR2|12|
Date/Time to Service Organization|BFDORG|DATE| |
Thurber Date (obsolete)|BFDTHURB|DATE| |
Date/Time Notice of Disagreement Received|BFDNOD|DATE| |
Date/Time Statement of the Case Issued|BFDSOC|DATE| |
Date/Time Form 9 Received|BFD19|DATE| |
Date/Time Certified to BVA|BF41STAT|DATE| |
Mail Status|BFMSTAT|VARCHAR2|1|
Appeal Status|BFMPRO|VARCHAR2|3|
Mail Control Date/Time|BFDMCON|DATE| |Remand returned date/Advance sent to BVA date
Regional Office|BFREGOFF|VARCHAR2|16| |Regional Office
Number of Issues (computed via batch update)|BFISSNR|VARCHAR2|1|
Remand Destination (RO, AMC, VHA, NCA, GC)|BFRDMREF|VARCHAR2|1|D=AMC R=RO V=VHA G=GC N=NCA
Appeal Program Area|BFCASEV|VARCHAR2|4|
Not Used|BFCASEVA|VARCHAR2|4|
Not Used|BFCASEVB|VARCHAR2|4|
Not Used|BFCASEVC|VARCHAR2|4|
Decision Team|BFBOARD|VARCHAR2|10|
Date/Time Assigned to Decision Team|BFBSASGN|DATE| |
Attorney ID|BFATTID|VARCHAR2|16|
Date/Time assigned to Attorney|BFDASGN|DATE| |
CAVC folder number|BFCCLKID|VARCHAR2|16|
Date/Time sent to Quality Review|BFDQRSNT|DATE| |
Date/Time Location In|BFDLOCIN|DATE| |
Date/Time Location Out|BFDLOOUT|DATE| | | how long the case has been ready to distribute
Medical Facility|BFSTASGN|VARCHAR2|16|
Current Location of Case File|BFCURLOC|VARCHAR2|10| |Location Code (99 - Full Grant, 97 - Partial/Remand)
Total Number of Copies for Duplication|BFNRCOPY|VARCHAR2|4|
Board Member Id|BFMEMID|VARCHAR2|16|
Date/Time assigned Board Member|BFDMEM|DATE| |
Number of Copies for Congressional Interest|BFNRCI|VARCHAR2|5|
Outbased Travel Board Ind|BFCALLUP|CHAR|1|
CAPRI Patient List Add/Del Indicator|BFCALLYYMM|VARCHAR2|4|
GenPop ind for Ret VLJ Hearing cases|BFHINES|VARCHAR2|2|GP or null
DRO Informal Hearing|BFDCFLD1|VARCHAR2|2|Y or Null
DRO Formal Hearing|BFDCFLD2|VARCHAR2|2|Y or Null
DRO|BFDCFLD3|VARCHAR2|2|Y or Null
Type Action|BFAC|VARCHAR2|1|
Disposition of Appeal|BFDC|VARCHAR2|1| |Disposition of Appeal -- see notes above table
Hearing Action|BFHA|VARCHAR2|1|
Not Used|BFIC|VARCHAR2|2|
Not Used (old Primary Issue Code used prior to 6/99)|BFIO|VARCHAR2|2|
Mailing Status|BFMS|VARCHAR2|1|R - Remand returned A - Adv Sent
Opinion Code|BFOC|VARCHAR2|1|
Special Handling|BFSH|VARCHAR2|1|
Service Organization|BFSO|VARCHAR2|1| |Service organization (exclude 'T')
Travel Board Hearing Requested|BFHR|VARCHAR2|1|
DRO Partial Grant/Denial (P or D)|BFST|VARCHAR2|1|
RO Notification Date|BFDRODEC|DATE| |
Date/Time Supplement Statement of Case Issued|BFSSOC1|DATE| |
Date/Time Supplement Statement of Case Issued|BFSSOC2|DATE| |
Date/Time Supplement Statement of Case Issued|BFSSOC3|DATE| |
Date/Time Supplement Statement of Case Issued|BFSSOC4|DATE| |
Date/Time Supplement Statement of Case Issued|BFSSOC5|DATE| |
Date/Time of Travel Board Request|BFDTB|DATE| |
Travel Board Ready|BFTBIND|VARCHAR2|1|
Date/Time of CUE|BFDCUE|DATE| |
Date in Development|BFDVIN|DATE| |
Date out of Development|BFDVOUT|DATE| |
Date DRO requested|BFDDRO|DATE| |
DRO Id|BFDROID|VARCHAR2|3|
Date development work began|BFDDVWRK|DATE| |
Date developent dispatched|BFDDVDSP|DATE| |
Date development returned|BFDDVRET|DATE| |
Ready to Rate by DRO|BFDRORTR|VARCHAR2|1|
Resource Center (Remands)|BFRO1|VARCHAR2|4|RO15, RO25, RO17, RO46, RO97
OVLJ Admin Action|BFLOT|VARCHAR3|2|
Specialty Case Tracking (SCT) group|BFBOX|VARCHAR4|4|
Date Ready for Travel Board|BFDTBREADY|DATE| |
Appeals Recource Center (for brokered appeals)|BFARC|VARCHAR4|4|
Date to ARC|BFDARCIN|DATE| |
Date from ARC|BFDARCOUT|DATE| |
ARC (Broker) disposition|BFARCDISP|VARCHAR2|1|
Substitution appeal indicator|BFSUB|VARCHAR2|1|"S" or null
Rocket Docket indicator|BFROCDOC|VARCHAR2|1|S = Selected or R = Reviewed not selected H=Hearing select
Rocket Docket date|BFDROCKET|DATE| |
{{< /details >}}

### CORRES (Veteran/Appellant)
  * SNAMEF, SNAMEL, SSN - basic Info
  * STAFKEY - connects to BRIEFF

{{< details "CORRES (Veteran/Appellant) table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Unique Primary Key|STAFKEY|VARCHAR2|16|Brieff(bfcorkey), Folder(ticorkey)
Not Used|SUSRPW|VARCHAR2|16|
Not Used|SUSRSEC|VARCHAR2|5|
Relationship to Veteran|SUSRTYP|VARCHAR2|10|Values = Veteran, Widow, Child, Parent, Other
Salutation|SSALUT|VARCHAR2|15|
First Name of Veteran|SNAMEF|VARCHAR2|24|
Middle Initial of Veteran|SNAMEMI|VARCHAR2|4|
Last Name of Veteran|SNAMEL|VARCHAR2|60|
Appellant ID/Claim Number|SLOGID|VARCHAR2|16|
Appellant Title|STITLE|VARCHAR2|40|
Organization|SORG|VARCHAR2|50|
Department|SDEPT|VARCHAR2|50|
Not Used|SADDRNUM|VARCHAR2|10|
First Line of Appellant Residence Address|SADDRST1|VARCHAR2|60|
Second Line of Appellant Residence Address|SADDRST2|VARCHAR2|60|
Appellant Residence City|SADDRCTY|VARCHAR2|20|
Appellant Residence State|SADDRSTT|VARCHAR2|4|
Appellant Residence Country|SADDRCNTY|VARCHAR2|6|
Appellant Residence Zip Code|SADDRZIP|VARCHAR2|10|
Appellant Work Phone Number|STELW|VARCHAR2|20|
Appellant Extra Phone Number|STELWEX|VARCHAR2|20|
Appellant Residence Fax Number|STELFAX|VARCHAR2|20|
Appellant Home Phone Number|STELH|VARCHAR2|20|
Staff Member Who Added Correspondence|STADUSER|VARCHAR2|16|
Date/Time Correspondence Added|STADTIME|DATE| |
Staff Member Who Modified Correspondence|STMDUSER|VARCHAR2|16|
Date/Time Correspondence Modified|STMDTIME|DATE| |
Not Used|STC1|NUMBER|22|
Not Used|STC2|NUMBER|22|
Not Used|STC3|NUMBER|22|
Not Used|STC4|NUMBER|22|
Notes|SNOTES|VARCHAR2|80|
Not Used|SORC1|NUMBER|22|
Not Used|SORC2|NUMBER|22|
Not Used|SORC3|NUMBER|22|
Not Used|SORC4|NUMBER|22|
Active/Inactive Flag|SACTIVE|VARCHAR2|1|
Not Used|SSYS|VARCHAR2|16|
Appellant Last Name (if different from Veteran)|SSPARE1|VARCHAR2|20|
Appellant First Name|SSPARE2|VARCHAR2|20|
Appellant MI|SSPARE3|VARCHAR2|20|
Appellant Suffix|SSPARE4|VARCHAR2|10|
Social Security Number|SSN|VARCHAR2|9| | Jed: According to Ivy they enter the SSN of the Veteran.
Date/Time Final Notice of Death|SFNOD|DATE| |
Date of Birth of Appellant|SDOB|DATE| | | [#207](https://github.com/department-of-veterans-affairs/dsva-vacols/issues/207)
Gender of Appellant|SGENDER|VARCHAR2|1| | [#207](https://github.com/department-of-veterans-affairs/dsva-vacols/issues/207)
Homeless Vet|SHOMELESS|VARCHAR2|1|
Terminally Ill|STERMILL|VARCHAR2|1|
Financial Hardship|SFINHARD|VARCHAR2|1|
Advanced Age|SADVAGE|VARCHAR2|1|
Medal of Honor|SMOH|VARCHAR2|1|
Very Serious Ilnnes|SVSI|VARCHAR2|1|
POW|SPOW|VARCHAR2|1|
ALS|SALS|VARCHAR2|1|
Persian Gulf War Veteran|SPGWV|VARCHAR2|1|
{{< /details >}}

### CORRTYPS

{{< details "CORRTYPS table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Primary key|CTYPKEY|VARCHAR2|16|Corres(stafkey)
Type value (PS0-9, POW, PWGV)|CTYPVAL|VARCHAR2|10|
User adding record|CTYADUSR|VARCHAR2|16|
Record add date|CTYADTIM|DATE| |
User last modifying record|CTYMDUSR|VARCHAR2|16|
Date last modified|CTYMDTIM|DATE| |
Not used|CTYACTVE|VARCHAR2|1|
Not used|CTYSYS|VARCHAR2|16|
{{< /details >}}

### COVA

{{< details "COVA table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Folder Number|CVFOLDER|VARCHAR2|12|Assign(tsktknm), Brieff(bfkey),Folder(ticknum), Hearsched(folder\_nr), Priorloc(lockey)
COVA Docket Number|CVDOCKET|VARCHAR2|7|
COVA Decision Date|CVDDEC|DATE| |
Joint Decision Indicator|CVJOINT|VARCHAR2|1|
COVA Disposition Code|CVDISP|VARCHAR2|1|
Board Member 1|CVBM1|VARCHAR2|3|
Board Member 2|CVBM2|VARCHAR2|3|
Board Member 3|CVBM3|VARCHAR2|3|
More than 3 Board Members Indicator|CVBM3PLUS|VARCHAR2|1|
Remand Reasons|CVRR|VARCHAR2|26|
Federal Circuit Indicator|CVFEDCIR|VARCHAR2|1|
30 Day Letter sent Indicator|CV30DIND|VARCHAR2|1|
Date 30 day letter sent|CV30DATE|DATE| |
COVA Location Code|CVLOC|VARCHAR2|1|
COVA Issue Sequence Number|CVISSSEQ|NUMBER|3|
COVA Judgement|CVJUDGEMENT|DATE| |
COVA Mandate|CVMANDATE|DATE| |
COVA Comments|CVCOMMENTS|VARCHAR2|2000|
Litigation Material indicator|CVLITMAT|VARCHAR2|1|
COVA Appeal Status|CVSTATUS|VARCHAR2|1|
Joint Motion Remand indicator|CVJMR|VARCHAR2|1|
Date of Joint Motion Remand|CVJMRDATE|DATE| |
Representative|CVREP|VARCHAR2|1|
COVA Remand Reasons free text|CVRRTEXT|VARCHAR3|160|
{{< /details >}}

### FOLDER (More claim info)
- TIVBMS - Appeal in VBMS?
  * From Caseflow: [folder.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/vacols/folder.rb)

{{< details "FOLDER table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Folder Number|TICKNUM|VARCHAR2|12|Assign(tsktknm), Attach(imgtkky) Brieff(bfkey), Hearsched(folder_nr), Priorloc(lockey)
Corres table key|TICORKEY|VARCHAR2|16|Corres(stafkey)
Staff Owner|TISTKEY|VARCHAR2|16|
Docket Number|TINUM|VARCHAR2|20|
Reason for Advancing on Docket|TIFILOC|VARCHAR2|20|
CAVC Docket Nr (for Motions)|TIADDRTO|VARCHAR2|10|
Appeal Id|TITRNUM|VARCHAR2|20|Vet's file number
Not Used|TICUKEY|VARCHAR2|10|
Not Used|TIDSNT|DATE| |
Date/Time Folder Received at BVA|TIDRECV|DATE| |
ECA Revoked (db trigger)|TIDDUE|DATE| |
Date/Time of Decision|TIDCLS|DATE| |
Motion Notes (for Motions)|TIWPPTR|VARCHAR2|250|
Not Used|TIWPPTRT|VARCHAR2|2|
Staff Who Added to Docket|TIADUSER|VARCHAR2|16|
Date/Time Added to Docket|TIADTIME|DATE| |
Staff that Last Modified|TIMDUSER|VARCHAR2|16|
Date/Time Last Modified|TIMDTIME|DATE| |
Transfer Date (AMO batch broker)|TICLSTME|DATE| |
Transferring Regional Office|TIRESP1|VARCHAR2|5|
Key Word|TIKEYWRD|VARCHAR2|250|
Not Used|TIACTIVE|VARCHAR2|1|
GC Attorney Last (for Motions)|TISPARE1|VARCHAR2|30|
GC Attorney First (for Motions)|TISPARE2|VARCHAR2|20|
Character Count for Decision (Archive Process)|TISPARE3|VARCHAR2|30|
Not Used|TIREAD1|VARCHAR2|28|
Citation Number|TIREAD2|VARCHAR2|16|
Not Used|TIMT|VARCHAR2|10|
ECA Appeal ind.|TISUBJ1|VARCHAR2|1|
NOA filed (for Motions)|TISUBJ|VARCHAR2|1|
Paperless Appeal (Virtual VA)|TISUBJ2|VARCHAR2|1|
Not Used|TISYS|VARCHAR2|16|
Special Interests Agent Orange|TIAGOR|VARCHAR2|1|
Asbestos|TIASBT|VARCHAR2|1|
Gulf War Undiagnosed Illness|TIGWUI|VARCHAR2|1|
Hepatitis C|TIHEPC|VARCHAR2|1|
AIDS/HIV|TIAIDS|VARCHAR2|1|
Mustard Gas|TIMGAS|VARCHAR2|1|
PTSD|TIPTSD|VARCHAR2|1|
Radiation Bomb|TIRADB|VARCHAR2|1|
Radiation Non-bomb|TIRADN|VARCHAR2|1|
Sarcoidosis|TISARC|VARCHAR2|1|
Sexual Harrasement|TISEXH|VARCHAR2|1|
Tobacco|TITOBA|VARCHAR2|1|
No Special Contentions|TINOSC|VARCHAR2|1|
38 U.S.C. 1151|TI38US|VARCHAR2|1|
No New and Material|TINNME|VARCHAR2|1|
Not well grounded|TINWGR|VARCHAR2|1|
Pre-discharge VA Exam|TIPRES|VARCHAR2|1|
Total rating termination|TITRTM|VARCHAR2|1|
No Other contentions|TINOOT|VARCHAR2|1|
Outcode Date|TIOCTIME|DATE| | |Outcoding date (make sure BFDEC is the same)
Outcoder|TIOCUSER|VARCH(A1R6)2|16|
Case Review date|TIDKTIME|DATE| |
Case Review processor|TIDKUSER|VARCH(A16R)2|16|
Pulac Order Date (for Motions)|TIPULAC|DATE| |
Cerullo Order Date (for Motions)|TICERULLO|DATE| |
Pilot Standardized NOD|TIPLNOD|VARCHAR2|1|
Pilot Waiver Form|TIPLWAIVER|VARCHAR2|1|
Pilot Express Lane|TIPLEXPRESS|VARCHAR2|1|
SNL indicator|TISNL|VARCHAR3|1|
VBMS appeal indicator|TIVBMS|VARCHAR4|1|
{{< /details >}}

### HEARSCHED
  * From Caseflow: [case_hearing.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/vacols/case_hearing.rb)
  * Caseflow’s `legacy_hearings.vacols_id` corresponds to VACOLS’ `hearsched.hearing_pkseq`
    * mentioned in [dsva-vacols#124](https://github.com/department-of-veterans-affairs/dsva-vacols/issues/124)

{{< details "HEARSCHED table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Hearing Sequence Number|HEARING\_PKSEQ|NUMBER|22|
Hearing Type|HEARING\_TYPE|VARCHAR2|1|See Appendix 1
Folder Number|FOLDER\_NR|VARCHAR2|12|Assign(tsktknm), Attach(imgtkky) Brieff(bfkey), Folder(ticknum), Priorloc(lockey)
Date/Time of Hearing|HEARING\_DATE|DATE| |
Hearing Disposition|HEARING\_DISP|VARCHAR2|1|
Board Member|BOARD\_MEMBER|VARCHAR2|20|
Notes|NOTES1|VARCHAR2|100|
BVA Decision Team|TEAM|VARCHAR2|2|
Hearing Room Number|ROOM|VARCHAR2|4|
State for Service Organization|REP\_STATE|VARCHAR2|2|
Last Modified by|MDUSER|VARCHAR2|16|
Date/Time last modified|MDTIME|DATE| |
Request date|REQDATE|DATE| |
Close date|CLSDATE|DATE| |
Recording media type|RECMED|VARCHAR2|1|
Date sent to Contactor|CONSENT|DATE| |
Date returned from Contractor|CONRET|DATE| |
Tapes sent to Contractor|CONTAPES|VARCHAR2|1|
Transcript request from Vet|TRANREQ|VARCHAR2|1|
Transcript sent to Vet|TRANSENT|DATE| |
Takes sent to Wilkes-Barre|WBTAPES|NUMBER|1|
Wilkes-Barre backup indicator|WBBACKUP|VARCHAR2|1|
Date tapes sent to Wilkes-Barre|WBSENT|DATE| |
Digital recording problem|RECPROB|VARCHAR2|1|
Contractor task Number|TASKNO|VARCHAR2|7|
User adding record|ADDUSER|VARCHAR2|16|
Date record added|ADDTIME|DATE| |
Advance on Docket indicator|AOD|VARCHAR2|1|
Hold Days for VLJ|HOLDAYS|NUMBER|3|
Virtual Docket key|VDKEY|VARCHAR2|12|
Hearing Represenative's name|REPNAME|VARCHAR2|25|
Virtual Docket BVA POC|VDBVAPOC|VARCHAR2|30|
Virtual Docket RO POC|VDROPOC|VARCHAR2|30|
Cancellation notification date|CANCELDATE|DATE| |
{{< /details >}}

### ISSREF (issue reference)

{{< details "ISSREF table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Program Code|PROG\_CODE|VARCHAR2|6|
Program Description|PROG\_DESC|VARCHAR2|50|
Issue Code|ISS\_CODE|VARCHAR2|6|
Issue Description|ISS\_DESC|VARCHAR2|50|
Level 1 Code|LEV1\_CODE|VARCHAR2|6|
Level 1 Description|LEV1\_DESC|VARCHAR2|50|
Level 2 Code|LEV2\_CODE|VARCHAR2|6|
Level 2 Description|LEV2\_DESC|VARCHAR2|50|
Level 3 Code|LEV3\_CODE|VARCHAR2|6|
Level 3 Description|LEV3\_DESC|VARCHAR2|50|
{{< /details >}}

### ISSUES
(case issues; regarding claim (medical,etc), also connects to appeal type)
  * From Caseflow: [issue.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/issue.rb)

{{< details "ISSUES table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Key to Table|ISSKEY|VARCHAR2|12|Brieff(bfkey), Rmdrea(rmdkey)
Issue Sequence|ISSSEQ|NUMBER|22|
Issue Program|ISSPROG|VARCHAR2|6|
Issue Code|ISSCODE|VARCHAR2|6|
Level 1 Code|ISSLEV1|VARCHAR2|6|
Level 2 Code|ISSLEV2|VARCHAR2|6|
Level 3 Code|ISSLEV3|VARCHAR2|6|
Issue Disposition Code|ISSDC|VARCHAR2|1|
Issue Disposition Date|ISSDCLS|DATE| |
Date/Time Issue was Added|ISSADTIME|DATE| |
Issue Added by|ISSADUSER|VARCHAR2|16|
Date/Time Issue was Modified|ISSMDTIME|DATE| |
Issue Modified By|ISSMDUSER|VARCHAR2|16|
Issue Description|ISSDESC|VARCHAR2|100|
Issue selected|ISSSEL|VARCHAR2|1|
Reason for Grant|ISSGR|VARCHAR2|1|(RO = CUE, De Novo, New Evidence)<br/>(BVA = AOJ Error, New Evidence, Change in Law)
Issue Development Flag|ISSDEV|VARCHAR2|1|Y'
{{< /details >}}

### MAIL

{{< details "MAIL table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Folder Number|MLFOLDER|VARCHAR2|12|Brieff (bfkey)
Mail Sequence Nr|MLSEQ|NUMBER|22|
Corres key (for Congressional Interests)|MLCORKEY|VARCHAR2|16|Corres (stafkey)
Source (Mail, Fax, Phone, RO)|MLSOURCE|VARCHAR2|1|
Mail Type (Congressional, POA, Hearing, etc.)|MLTYPE|VARCHAR2|2|
Date of Correspondence|MLCORRDATE|DATE| |
Date Correspondence Received|MLRECVDATE|DATE| |
Action Due Date|MLDUEDATE|DATE| |
Action Completion Date|MLCOMPDATE|DATE| |
Final Action|MLACTION|VARCHAR2|2|
Mail Assigned to|MLASSIGNEE|VARCHAR2|16|
Notes|MLNOTES|VARCHAR2|80|
Mail Added by|MLADDUSER|VARCHAR2|16|
Date/Time Added|MLADDTIME|DATE| |
Mail last modified|MLMODUSER|VARCHAR2|16|
Date/Time last modified|MLMODTIME|DATE| |
Controlled Correspondence (Y/N)|MLCONTROL|VARCHAR2(1)| |
EDMS number|MLEDMS|VARCHAR2(10)| |
Mail action date|MLACTDATE|DATE| |
FOIA/PA requestor last|MLREQLAST|VARCHAR2(25)| |
FOIA/PA requestor first|MLREQFIRST|VARCHAR2(15)| |
FOIA/PA requestor mi|MLREQMI|VARCHAR2(1)| |
FOIA/PA requestor relationship|MLREQREL|VARCHAR2(1)| |
FOIA/PA requestor access|MLACCESS|VARCHAR2(1)| |
FOIA/PA requestor amendment|MLAMEND|VARCHAR2(1)| |
FOIA/PA requestor litigation|MLLIT|VARCHAR2(1)| |
FOIA/PA requestor fee|MLFEE|NUMBER(8,2)| |
FOIA/PA requestor pages|MLPAGES|NUMBER(5)| |
FOIA/PA requestor addresss line1|MLADDR1|VARCHAR2(40)| |
FOIA/PA requestor address line2|MLADDR2|VARCHAR2(40)| |
FOIA/PA requestor city|MLCITY|VARCHAR2(20)| |
FOIA/PA requestor state|MLST|VARCHAR2(4)| |
FOIA/PA requestor zip|MLZIP|VARCHAR2(10)| |
Date received FOIA/PA Office|MLFOIADATE|DATE| |
FOIA/PA Requesting Facility|MLREQFAC|VARCHAR2(25)| |
FOIA/PA Tracking Status|MLTRACK|VARCHAR2(1)| |
FOIA/PA Tracking due date2|MLDUE2ND|DATE| |
FOIA/PA Tracking check authorization ind.|MLAUTH|VARCHAR2(1)| |
{{< /details >}}

### PRIORLOC (prior locations)
(claim location history)

{{< details "PRIORLOC table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Sub-Location|LOCLCODE|VARCHAR2|10|Shelf loc, VSO emp, Home charge (bforgtic)|
Folder Related To|LOCKEY|VARCHAR2|12|Assign(tsktknm), Attach(imgtkky) Brieff(bfkey), Folder(ticknum), Hearsched(folder\_nr)|
Location Check-In Date|LOCDIN|DATE| | |
Location Check-Out Date|LOCDOUT|DATE| | |
Staff to Whom Case File was sent|LOCSTTO|VARCHAR2|16|Brieff(bfcurloc)|an org or person
Staff who received Case file|LOCSTRCV|VARCHAR2|16| |a person (in the org)
Staff Who Checked Out Case File|LOCSTOUT|VARCHAR2|16| |equal to LOCSTRCV in previous location
Exception Flag|LOCEXCEP|VARCHAR2|10| |
Not used|LOCDTO|DATE| | |
{{< /details >}}

### OTHDOCS
  * CLMFLD - 3 characters; Claims folder volumes; "for virtual appeals the value should be left null ... should only be entered for paper cases and is normally 1 or 2 volumes" [ref](https://github.com/department-of-veterans-affairs/dsva-vacols/issues/97)

{{< details "OTHDOCS table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Primary key|TICKNUM|VARCHAR2|12|Brieff(bfkey)
Claims folder volumes|CLMFLD|VARCHAR2|3|
Inactive claims folders|INCLMFLD|VARCHAR2|3|
X-rays|XRAY|VARCHAR2|3|
Slides|SLIDES|VARCHAR2|3|
Tissue Blocks|TISBLK|VARCHAR2|3|
Education folders|VREFLD|VARCHAR2|3|
WOE folders|WOEFLD|VARCHAR2|3|
OE folders|OEFLD|VARCHAR2|3|
Counseling / Traning folder|CNSLTRN|VARCHAR2|3|
Loan Guaranty folder|LNGRN|VARCHAR2|3|
Insuracne folders|INSFLD|VARCHAR2|3|
Dental exam folders|DNLFLD|VARCHAR2|3|
Outpatient treatment folder|OUTTRT|VARCHAR2|3|
Clinical exams|CLINICAL|VARCHAR2|3|
Hospital correspondence folder|HSPCOR|VARCHAR2|3|
Guardianship documents|GRDSHP|VARCHAR2|3|
Investigation folder|INVFLD|VARCHAR2|3|
Other Medical folders|OTHMED|VARCHAR2|3|
Income Verification Match (IVM) folder|OTHLEG|VARCHAR2|3|
Other folders|OTHER|VARCHAR2|3|
Service Department Envelope|SDRENV|VARCHAR2|3|
Other folder description|OTHDESC|VARCHAR2|30|
Co-pay folders|COPAY|VARCHAR2|3|
{{< /details >}}

### RMDREA

{{< details "RMDREA table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Key to Table|RMDKEY|VARCHAR2|12|Issues(isskey), Brieff(bfkey)
Remand Value|RMDVAL|VARCHAR2|2|
Staff Who Modified Remand Reason|RMDMDUSR|VARCHAR2|16|
Date/Time Remand Reason Modified|RMDMDTIM|DATE| |
Remand Priority|RMDPRIORITY|VARCHAR2|2|
Remand Issue Sequence|RMDISSSEQ|NUMBER|22|
Remand Development Reason|RMDDEV|VARCHAR2|2|R1' = RO Error; 'R2' = Post RO Event
{{< /details >}}

### REP (representatives)
(representatives of veterans/claimants)
  * [representative.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/vacols/representative.rb)

{{< details "REP table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Key to Table (Folder Nr.)|REPKEY|VARCHAR2(12)| |Brieff (bfkey)
Date added|REPADDTIME|DATE| |
Rep Type (Attorney/Agent/Contesting Appellant)|REPTYPE|VARCHAR2(1)| |
Service Organization|REPSO|VARCHAR2(1)| |
Last Name|REPLAST|VARCHAR2(40)| |
First Name|REPFIRST|VARCHAR2(24)| |
Middle Initial|REPMI|VARCHAR2(4)| |
Suffix|REPSUF|VARCHAR2(4)| |
Address line 1|REPADDR1|VARCHAR2(50)| |
Address line 2|REPADDR2|VARCHAR2(50)| |
City|REPCITY|VARCHAR2(20)| |
State|REPST|VARCHAR2(4)| |
Zip|REPZIP|VARCHAR2(10)| |
Phone number|REPPHONE|VARCHAR2(20)| |
Notes|REPNOTES|VARCHAR2(50)| |
Last modified by|REPMODUSER|VARCHAR2(16)| |
Date last modified|REPMODTIME|DATE| |
Direct Pay indicator|REPDIRPAY|VARCHAR2(1)| |
Date of Attorney fee agreement|REPDFEE|DATE| |
Date fee agreement received BVA|REPFEERECV|DATE| |
Date last document sent|REPLASTDOC|DATE| |
Date attorney fee dispatched|REPFEEDISP|DATE| |
Corres table key|REPCORKEY|VARCHAR2(16)| |Corres (stafkey)
Date acknowledgement letter sent|REPACKNW|DATE| |
{{< /details >}}

### STAFF
  * `VACOLS::Staff.count => 4072`
  * Active/Inactive Flag: SACTIVE,  1 char, A= Active; I= Inactive
    * `VACOLS::Staff.select(:sactive).distinct.pluck(:sactive) => ["A", "I", nil, "V"]`
  * Attorney Number:  SATTYID,  4 chars
    * `VACOLS::Staff.select(:sattyid).distinct.size => 2047`
  * VLJ (A or J): SVLJ, 1 char
    * `VACOLS::Staff.select(:svlj).distinct.pluck(:svlj) => [nil, "I", "A", "J"]`
      * `svlj = "J"` : Judge
      * `svlj = "A"` : Acting Judge
      * `svlj = nil` : Attorney
  * [Stats for Attorneys, Judges, Acting Judges](https://github.com/department-of-veterans-affairs/caseflow/pull/13366#issuecomment-583189359)
  * Uses from Caseflow: [attorney_repository.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/repositories/attorney_repository.rb), [judge_repository.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/repositories/judge_repository.rb), [user_repository.rb](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/repositories/user_repository.rb)


{{< details "STAFF table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Key to Table|STAFKEY|VARCHAR2|16|Assign(tskstfas, tskadusr, tskmdusr), Attach(imgowner,imgadusr,imgmdusr, imread2), Brieff(bfattid, bfcclkid, bfstasgn), Folder(tiaduser, timduser), Corres(staduser, stmduser), Priorloc(locstrv, locstout, locstto)
Password|SUSRPW|VARCHAR2|16|
User Security Level|SUSRSEC|VARCHAR2|5|
Staff User Type - ARC indicator|SUSRTYP|VARCHAR2|10|Also used for ROADMIN = RO VACOLS Administrator
Staff Member Salutation|SSALUT|VARCHAR2|15|
Staff Member First Name|SNAMEF|VARCHAR2|24|
Staff Member Middle Initial|SNAMEMI|VARCHAR2|4|
Staff Member Last Name|SNAMEL|VARCHAR2|60|
Staff Member Unique ID|SLOGID|VARCHAR2|16|
Staff Member Title|STITLE|VARCHAR2|60|
Staff Member Organization|SORG|VARCHAR2|60|
Staff Member Department|SDEPT|VARCHAR2|60|
DAS Security|SADDRNUM|VARCHAR2|10|3=Admin 2=Delete
First Line of Staff Member Street Address|SADDRST1|VARCHAR2|30|
Second Line of Staff Member Street Address|SADDRST2|VARCHAR2|30|
Staff Member City|SADDRCTY|VARCHAR2|20|
Staff Member State|SADDRSTT|VARCHAR2|4|
Staff Member Country|SADDRCNTY|VARCHAR2|6|
Staff Member Zip Code|SADDRZIP|VARCHAR2|10|
Staff Member Work Phone Number|STELW|VARCHAR2|20|
Staff Member Work Phone Extension|STELWEX|VARCHAR2|20|
Staff Member Fax Number|STELFAX|VARCHAR2|20|
Staff Member Home Phone Number|STELH|VARCHAR2|20|
Staff Record Added By|STADUSER|VARCHAR2|16|
Date/Time Staff Record Added|STADTIME|DATE| |
Staff Record Modified By|STMDUSER|VARCHAR2|16|
Date/Time Staff Record Modified|STMDTIME|DATE| |
Open Folders|STC1|NUMBER|22|
RO TB Hearing Limit Mon/Fri|STC2|NUMBER|22|
RO TB Hearing Limit Tue/Wed/Thu|STC3|NUMBER|22|
RO Video Hearing Limit|STC4|NUMBER|22|
Notes|SNOTES|VARCHAR2|80|
Mail Security|SORC1|NUMBER|22|
Hearing Security|SORC2|NUMBER|22|
Atty Fee Security|SORC3|NUMBER|22|
QR Security|SORC4|NUMBER|22|
Active/Inactive Flag|SACTIVE|VARCHAR2|1|A= Active; I= Inactive
Flexiplace Ind|SSYS|VARCHAR2|16|
RO Pilot program indicator|SSPARE1|VARCHAR2|20|Y' or 'N'
RO Case Flow indicatior|SSPARE2|VARCHAR2|20|Y' or 'N'
Not Used|SSPARE3|VARCHAR2|20|
Writes for VLJ|SMEMGRP|VARCHAR2|16|
FOIA Security access|SFOIASEC|NUMBER|1|
VACOLS Reports access|SRPTSEC|NUMBER|1|
Attorney Number|SATTYID|VARCHAR2|4|
VLJ (A or J)|SVLJ|VARCHAR2|1|
Inventory Security|SINVSEC|VARCHAR2|1|
{{< /details >}}

### VFTYPES

{{< details "VFTYPES table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Key to Table|FTKEY|VARCHAR2|10|RRAA - RREK for new FY05 Remand Reasons
Lookup Description|FTDESC|VARCHAR2|100|Remand Reason Description
Lookup Description Added by|FTADUSR|VARCHAR2|16|
Date/Time Lookup Description Added|FTADTIM|DATE| |
Lookup Description Modified By|FTMDUSR|VARCHAR2|16|
Date lookup Description Modified|FTMDTIM|DATE| |
Active/Inactive Flag|FTACTIVE|VARCHAR2|1|
Lookup Code Type|FTTYPE|VARCHAR2|16|R5 = New Remand Reasons for FY05
Not Used|FTSYS|VARCHAR2|16|Remand Reason Category
Not Used|FTSPARE1|VARCHAR2|20|
Not Used|FTSPARE2|VARCHAR2|20|
Not Used|FTSPARE3|VARCHAR2|20|
{{< /details >}}

## Other Tables

### COIN

{{< details "COIN table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Regional Office|COINRO|VARCHAR2|4|
Report Date|RPTDT|DATE| |
Num of NODs Current Month|NODCM|NUMBER|7|
Num of NODs Fiscal Year-To-Date|NODFY|NUMBER|7|
Num of NODs Pending Current Month|NODPNCM|NUMBER|7|
Total days for NODs Pending Current Month|DNODPNCM|NUMBER|9|
Num of SOCs Current Month|SOCCM|NUMBER|7|
Num of SOCs Fiscal Year-To-Date|SOCFY|NUMBER|7|
Total Days for SOCs Current Month|DSOCCM|NUMBER|9|
Total Days for SOCc Fiscal Year-To-Date|DSOCFY|NUMBER|9|
Num of Form 9s Current Month|F9CM|NUMBER|7|
Num of Form 9s Fiscal Year-To-Date|F9FY|NUMBER|7|
Total Days for Form 9s Current Month|DF9CM|NUMBER|9|
Total Days for Form 9s Fiscal Year-To-Date|DF9FY|NUMBER|9|
Num of Form 9s Without SSOCs|F9WOSSOC|NUMBER|7|
Num of Form 9s With SSOC|F9WSSOC|NUMBER|7|
Total Days for Form 9s Without SSOC|DF9WOSSOC|NUMBER|9|
Total Days for Form 9s With SSOC|DF9WSSOC|NUMBER|9|
Num of SSOCs Current Month|SSOCCM|NUMBER|7|
Num of SSOCs Fiscal Year-To-Date|SSOCFY|NUMBER|7|
Total Days for SSOCs Current Month|DSSOCCM|NUMBER|9|
Total Days for SSOCs Fiscal Year-To-Date|DSSOCFY|NUMBER|9|
Num of Appeals Certified Current Month|CERTCM|NUMBER|7|
Num of Appeals Certified Fiscal Year-To-Date|CERTFY|NUMBER|7|
Total Days for Appeals Certified Current Month|DCERTCM|NUMBER|9|
Total days for Appeals Certified Fiscal Year-To-date|DCERTFY|NUMBER|9|
{{< /details >}}

### DECREVIEW

{{< details "DECREVIEW table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Appellant id|APPEAL\_ID|VARCHAR2(10)|10|
Folder (primary key)|FOLDER|VARCHAR2(12)|12|Breiff(bfkey), Folder(ticknum)
QR Review date|REVIEW\_DATE|DATE| |
Issue|ISSUE|VARCHAR2(5)|5|
Difficulty|DIFFICULTY|VARCHAR2(1)|1|
QR Reviewer|USER\_ID|VARCHAR2(11)|11|
(**Exceptions:**) | | | | |
Raised but undeveloped issue(s) omitted|EX1|VARCHAR2(5)|5|
Developed issue(s) omitted|EX2|VARCHAR2(5)|5|
Inaccurate issues(s) set forth on title page|EX3|VARCHAR2(5)|5|
Inaccurate finding|EX4|VARCHAR2(5)|5|
Necessary elements of claim not addressed|EX5|VARCHAR2(5)|5|
Erroneous conclusion|EX6|VARCHAR2(5)|5|
Failure to address every relevant theory of entitlement|EX7|VARCHAR2(5)|5|
Legal authority misapplied: Case Law|EX8|VARCHAR2(5)|5|
Legal authority misapplied: Law or Regulation|EX9|VARCHAR2(5)|5|
Legal authority misapplied: Precedent opinion|EX10|VARCHAR2(5)|5|
Legal authority not applied: Case Law|EX11|VARCHAR2(5)|5|
Legal authority not applied: Law or Regulation|EX12|VARCHAR2(5)|5|
Legal authority not applied: Precedent opinion|EX13|VARCHAR2(5)|5|
Incorrect standard of proof|EX14|VARCHAR2(5)|5|
Inadequate explanation: Material evidence omitted|EX15|VARCHAR2(5)|5|
Inadequate explanation: Deficient credibility determ|EX16|VARCHAR2(5)|5|
Inadequate explanation: Conclusionary discussion|EX17|VARCHAR2(5)|5|
Inadequate explanation: Relevant theory not addressed|EX18|VARCHAR2(5)|5|
Fair process violation(Bernard,Colvin,Thurber)|EX19|VARCHAR2(5)|5|
Board Jurisdictional error(e.g., Marsh, Barnett)|EX20|VARCHAR2(5)|5|
Inadequate development|EX21|VARCHAR2(5)|5|
Failure of duty to notify|EX22|VARCHAR2(5)|5|
Procedural deficiency: Hearing|EX23|VARCHAR2(5)|5|
Procedural deficiency: Representation|EX24|VARCHAR2(5)|5|
Procedural deficiency: 38 C.F.R 20.1304|EX25|VARCHAR2(5)|5|
Procedural deficiency: Other|EX26|VARCHAR2(5)|5|
Typographical/grammatical errors|EX27|VARCHAR2(5)|5|
BVA Handbook 8430.2 not applied|EX28|VARCHAR2(5)|5|
Appeal misidentification|EX29|VARCHAR2(5)|5|
Internal inconsistency (Issue:FOF:COL:ORDER)|EX30|VARCHAR2(5)|5|
Essential decisional elements not present|EX31|VARCHAR2(5)|5|
Not used in NEW format|EX32|VARCHAR2(5)|5|
Not used in NEW format|EX33|VARCHAR2(5)|5|
Not used in NEW format|EX34|VARCHAR2(5)|5|
Not used in NEW format|EX35|VARCHAR2(5)|5|
Inaccurate Remand reasons|EX36|VARCHAR2(5)|5|
Not used in NEW format|EX37|VARCHAR2(5)|5|
Not used in NEW format|EX38|VARCHAR2(5)|5|
Decision or Motion|DECTYPE|VARCHAR2(1)|1|(D or M)
Record format|RECFORMAT|VARCHAR2(3)|3|(NEW = after 06/01/1999)
Last modified by|MODUSER|VARCHAR2(16)|16|
Last modified on|MODTIME|DATE| |
{{< /details >}}

### ACTCODE

{{< details "ACTCODE table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Diary code|ACTCKEY|VARCHAR2(10)| |Primary key join to ASSIGN.TSKACTCD
Diary description|ACTCDESC|VARCHAR2(50)| |
Not used|ACTCSEC|VARCHAR2(5)| |
Not used|ACTCUKEY|VARCHAR2(10)| |
Default numbr of days for Diary|ACTCDTC|VARCHAR2(3)| |
User Adding|ACTADUSR|VARCHAR2(16)| |
Date added|ACTADTIM|DATE| |
User last modifying|ACTMDUSR|VARCHAR2(16)| |
Date last modified|ACTMDTIM|DATE| |
Diary Active (A) or Inactive (I)|ACACTIVE|VARCHAR2(1)| |
RO or BVA diary|ACTSYS|VARCHAR2(16)| |
Additional diary description|ACTCDESC2|VARCHAR2(280)| |
Not used|ACSPARE1|VARCHAR2(20)| |
Not used|ACSPARE2|VARCHAR2(20)| |
Not used|ACSPARE3|VARCHAR2(20)| |
{{< /details >}}

### DECASS

{{< details "DECASS table" >}}
FIELD DESCRIPTION | FIELD NAME | TYPE | SIZE | RELATED TABLES/REMARKS | Our Notes
-----|-----|-----|-----|-----|-----
Folder number (Primary key)|DEFOLDER|VARCHAR2(12)| |Breiff(bfkey), Folder(ticknum)
Attorney number|DEATTY|VARCHAR2(16)| |
Decision Team|DETEAM|VARCHAR2(3)| |
Peliminary difficulty|DEPDIFF|VARCHAR2(1)| |
Final Difficulty|DEFDIFF|VARCHAR2(1)| |
Date Assigned|DEASSIGN|DATE| |
Date received by VLJ|DERECEIVE|DATE| |
Hours spent on case|DEHOURS|NUMBER(5,2)| |
Work Product|DEPROD|VARCHAR2(3)| |
Timeliness indicator|DETREM|VARCHAR2(1)| |Y or N
Additional Remarks (obsolete)|DEAREM|VARCHAR2(1)| |Y or N
Overall Quality|DEOQ|VARCHAR2(1)| |
Added by|DEADUSR|VARCHAR2(12)| |
Added on date/time|DEADTIM|DATE| |
Progress review date|DEPROGREV|DATE| |
Attorney comments|DEATCOM|VARCHAR2(350)| |
VLJ comments|DEBMCOM|VARCHAR2(600)| |
Last modified by|DEMDUSR|VARCHAR2(12)| |
Last modified on|DEMDTIM|DATE| |
DAS locked|DELOCK|VARCHAR2(1)| |
VLJ number|DEMEMID|VARCHAR2(16)| |
DAS completion date|DECOMP|DATE| |
Deadline date|DEDEADLINE|DATE| |
Intial Complexity rating|DEICR|NUMBER(5,2)| |
Final Complexity rating|DEFCR|NUMBER(5,2)| |
Quality Review item 1|DEQR1|VARCHAR2(1)| |
Quality Review item 2|DEQR2|VARCHAR2(1)| |
Quality Review item 3|DEQR3|VARCHAR2(1)| |
Quality Review item 4|DEQR4|VARCHAR2(1)| |
Quality Review item 5|DEQR5|VARCHAR2(1)| |
Quality Review item 6|DEQR6|VARCHAR2(1)| |
Quality Review item 7|DEQR7|VARCHAR2(1)| |
Quality Review item 8|DEQR8|VARCHAR2(1)| |
Quality Review item 9|DEQR9|VARCHAR2(1)| |
Quality Review item 10|DEQR10|VARCHAR2(1)| |
Quality Review item 11|DEQR11|VARCHAR2(1)| |
Decision document id|DEDOCID|VARCHAR2(30)| |
Recommened decision|DERECOMMEND|VARCHAR2(1)| |
One touch initiative|DE1TOUCH|VARCHAR2(1)| |
{{< /details >}}

</div>
