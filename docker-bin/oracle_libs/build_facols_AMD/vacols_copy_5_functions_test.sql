
  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ACT_CNT" (appealid CHAR)
  RETURN NUMBER AS
  actcnt number;
BEGIN
select count(*) into actcnt from BRIEFF where bfcorlid = appealid and
  bfmpro = 'ACT';

RETURN actcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ADV_CNT" (appealid CHAR)
  RETURN NUMBER AS
  advcnt number;
BEGIN
select count(*) into advcnt from BRIEFF where bfcorlid = appealid and
  bfmpro = 'ADV';

RETURN advcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."AMC_CNT" (folder CHAR)
  RETURN NUMBER AS
  amccnt number;
BEGIN
select count(*) into amccnt from PRIORLOC where lockey = folder and
  locstto = '98';

RETURN amccnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."AOD_B_CNT" (folder CHAR)
  RETURN NUMBER AS aodcnt number;


BEGIN
aodcnt := 0;

select count(*) into aodcnt from assign
  where tsktknm = folder and tskactcd = 'B';


RETURN aodcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."AOD_CNT" (folder CHAR)
  RETURN NUMBER AS
  aodcnt number;

dcnt number;
hcnt number;

BEGIN
dcnt := 0;
select count(*) into dcnt from assign
  where tsktknm = folder and tskactcd in ('B', 'B1', 'B2');

hcnt := 0;
select count(*) into hcnt from hearsched where folder_nr = folder
  and hearing_type in ('C', 'T', 'V', 'R') and aod in ('G', 'Y');

aodcnt := dcnt + hcnt;

RETURN aodcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."AOD_VSO_DUE" (folder CHAR)
  RETURN DATE AS
  duedate DATE;

BEGIN
select min(TSKDDUE) into duedate from assign
  where tsktknm = folder and tskactcd= 'B1' and tskdcls is null;
RETURN duedate;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."AOD_YN" (folder CHAR)
   RETURN CHAR AS aodyn varchar2(1);

dcnt number;
hcnt number;
aodcnt number;

BEGIN
aodcnt := 0;

dcnt := 0;
select count(*) into dcnt from assign
  where tsktknm = folder and tskactcd in ('B', 'B1', 'B2');

hcnt := 0;
select count(*) into hcnt from hearsched where folder_nr = folder
  and hearing_type in ('C', 'T', 'V', 'R') and aod in ('G', 'Y');

aodcnt := dcnt + hcnt;

if aodcnt > 0 then
  aodyn := 'Y';
else
  aodyn := 'N';
end if;


RETURN aodyn;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."APPEAL_CAT" (issue_code CHAR)
  RETURN CHAR AS
  appeal_cat varchar2(7);
BEGIN
if (issue_code = '09' or issue_code = '31') then
    appeal_cat := 'CH DIS';
elsif ((TO_NUMBER(issue_code) >= 1 and TO_NUMBER(issue_code) <= 8)
   or (TO_NUMBER(issue_code) >= 10 and TO_NUMBER(issue_code) <= 13)
   or issue_code = '92') then
    appeal_cat := 'DIS CMP';
elsif (issue_code = '16'
   or issue_code = '17'
   or issue_code = '19'
   or (TO_NUMBER(issue_code) >= 24 and TO_NUMBER(issue_code) <= 30)
   or (TO_NUMBER(issue_code) >= 32 and TO_NUMBER(issue_code) <= 35)) then
    appeal_cat := 'DIS PNS';
elsif (TO_NUMBER(issue_code) >= 36 and TO_NUMBER(issue_code) <= 45) then
    appeal_cat := 'DTH CMP';
elsif (TO_NUMBER(issue_code) >= 50 and TO_NUMBER(issue_code) <= 56) then
    appeal_cat := 'DTH PNS';
elsif (issue_code = '77'
   or issue_code = '78'
   or issue_code = '79') then
    appeal_cat := 'FORFEIT';
elsif (issue_code = '46'
   or issue_code = '47') then
    appeal_cat := 'ATY FEE';
elsif (issue_code = '80'
   or issue_code = '81'
   or issue_code = '82'
   or issue_code = '83') then
    appeal_cat := 'HOS OPT';
elsif ((TO_NUMBER(issue_code) >= 60 and TO_NUMBER(issue_code) <= 65)
   or (TO_NUMBER(issue_code) >= 93 and TO_NUMBER(issue_code) <= 96)) then
    appeal_cat := 'INSRNC';
elsif issue_code = '87' then
    appeal_cat := 'L/G';
elsif (TO_NUMBER(issue_code) >= 66 and TO_NUMBER(issue_code) <= 70) then
    appeal_cat := 'VR+E';
elsif (TO_NUMBER(issue_code) >= 71 and TO_NUMBER(issue_code) <= 75) then
    appeal_cat := 'WOEA';
elsif issue_code = '76' then
    appeal_cat := 'WAIVER';
elsif (issue_code = '84'
   or issue_code = '85'
   or issue_code = '86'
   or (TO_NUMBER(issue_code) >= 88 and TO_NUMBER(issue_code) <= 92)
   or issue_code = '97'
   or issue_code = '98'
   or issue_code = '00') then
    appeal_cat := 'MISC';
elsif issue_code = '99' then
   appeal_cat := 'RECONS';
end if;
RETURN appeal_cat;
END appeal_cat;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ATTACH_CHECK" (folder1 CHAR, doctype CHAR)
  RETURN CHAR AS atyn varchar2(1);

ctcnt number;

BEGIN
select count(*) into ctcnt from attach
 where imgtkky = folder1 and imgdoctp = doctype;

if ctcnt > 0 then
  atyn := 'Y';
else
  atyn := 'N';
end if;


RETURN atyn;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."CAVC_DISP" (folder1 CHAR)
  RETURN CHAR AS disp varchar2(1);

litcnt number;

BEGIN

select count(*) into litcnt from cova where cvfolder = folder1 and cvissseq is not null;
 if litcnt = 0 then
   select cvdisp into disp from cova where cvfolder = folder1;
   return disp;
end if;

select count(*) into litcnt from cova where cvfolder = folder1 and  cvissseq is not null and cvdisp in ('2','4','8');
if litcnt > 0 then
  return '2';
end if ;

select count(*) into litcnt from cova where cvfolder = folder1 and  cvissseq is not null and cvdisp in ('1','3');
if litcnt > 0 then
  return '1';
end if;

select count(*) into litcnt from cova where cvfolder = folder1 and  cvissseq is not null and cvdisp = '5';
if litcnt > 0 then
  return '5';
end if;

select count(*) into litcnt from cova where cvfolder = folder1 and  cvissseq is not null and cvdisp = '6';
if litcnt > 0 then
  return '6';
end if;

select count(*) into litcnt from cova where cvfolder = folder1 and  cvissseq is not null and cvdisp = '7';
if litcnt > 0 then
 return '7';
end if;

select count(*) into litcnt from cova where cvfolder = folder1 and  cvissseq is not null and cvdisp = '9';
if litcnt > 0 then
  return '9';
end if;


RETURN '0';
END;


/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."CAVC_ISSSEQ_CNT" (folder CHAR)
  RETURN NUMBER AS
  cvcnt number;
BEGIN

SELECT count(*) into cvcnt from COVA where CVFOLDER = folder
  and CVISSSEQ is not null ;


RETURN cvcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."CAVC_LITMAT" (folder1 CHAR,
    folder2 CHAR)
  RETURN CHAR AS lityn varchar2(1);

litcnt number;

BEGIN
select count(*) into litcnt from cova
 where cvfolder in (folder1, folder2)
 and cvlitmat = 'N';

if litcnt > 0 then
  lityn := 'N';
else
  lityn := 'Y';
end if;


RETURN lityn;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."CAVC_PREV" (docket CHAR, folder CHAR)
   RETURN NUMBER AS pcnt number;

BEGIN
select count(*) into pcnt from brieff, folder where bfkey = ticknum
 and tinum = docket and bfac = '7' and bfkey <> folder;

RETURN pcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."CHARGED_BY" (folder CHAR, loc CHAR)
  RETURN CHAR AS chargedby varchar2(16);

CURSOR DV_Cur is SELECT LOCSTOUT FROM PRIORLOC WHERE LOCKEY = folder
  AND LOCSTTO = loc order by LOCDOUT DESC;

BEGIN

OPEN DV_Cur;
FETCH DV_Cur into chargedby;
CLOSE DV_Cur;

RETURN chargedby;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DAV_CNT" (logid CHAR)
  RETURN NUMBER AS  actcnt number;

BEGIN
select count(*) into actcnt from BRIEFF where bforgtic = logid and
  bfmpro = 'ACT' and bfcurloc = '55';

RETURN actcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DAYS_FREQUENCY" (in_date DATE)
  RETURN CHAR AS  df VARCHAR2(20);

days number;

BEGIN
days := sysdate - in_date;

if days > 0 and days <= 150 then
   df := 'A 0-150';
elsif days > 150 and days <= 250 then
   df := 'B 151-250';
elsif days > 250 and days <= 350 then
   df := 'C 251-350';
elsif days > 350 and days <= 450 then
   df := 'D 351-450';
elsif days > 450 and days <= 550 then
   df := 'E 451-550';
elsif days > 550 and days <= 650 then
   df := 'F 551-650';
elsif days > 650 and days <= 750 then
   df := 'G 651-750';
elsif days > 750 and days <= 850 then
   df := 'H 751-850';
else
   df := 'I Over 850';
end if;

RETURN df;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DECASS_CATEGORY" (in_prod CHAR)
  RETURN CHAR AS cat varchar2(20);

BEGIN

CASE
   When in_prod in ('IME', 'VHA', 'AFI', 'OTV', 'OTI')
    then cat := 'Medical Opinions' ;
   ELSE cat := 'Decisions';
END CASE;

RETURN cat;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DECASS_COMPLEX" (folder CHAR)
  RETURN NUMBER AS   compcnt number;

sccnt number; totcnt number; ircnt number;  othcnt number;
vols number; efolders number; doccnt number;

BEGIN
select count(*) into totcnt from issues where isskey = folder
  and (issdc between '1' and '9' or issdc is null) ;

select count(*) into sccnt from issues where isskey = folder and issprog = '02' and isscode = '15'
  and (issdc between '1' and '9' or issdc is null) ;

select count(*) into ircnt from issues where isskey = folder and issprog = '02' and isscode in ('09' , '12', '17' )
  and (issdc between '1' and '9' or issdc is null) ;

select distinct to_number(clmfld), to_number(efolder) into vols, efolders from othdocs where ticknum = folder;
if efolders > 0  then
   doccnt := efolders / 100;
elsif vols > 0 then
   doccnt := vols;
else
   doccnt := 1;
end if;

othcnt := totcnt - sccnt - ircnt ;
compcnt :=  sccnt + (ircnt * 2)  + (othcnt * 3) + doccnt ;

RETURN compcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DECASS_CREDIT" (in_prod CHAR)
  RETURN number AS
  credit number;
BEGIN

CASE
   When in_prod in ('BOT', 'DIM', 'DVH', 'DAF', 'DRM', 'VDR') then credit := 1.5 ;
   when in_prod in ('REA', 'REU', 'DOR', 'RRC', 'OTD', 'OTR', 'OTB', 'OTV', 'OTI', 'COR', 'INT')  then  credit := 0;
   ELSE credit := 1;
END CASE;

RETURN credit;
END;

-- Keep in sync with f_credit in issues.pbl;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DECREV_EXCEP" (infolder CHAR, inissue NUMBER)
  RETURN CHAR AS exyn varchar2(1);

excnt number;
modcnt number;

BEGIN

-- If issue has not been modified/reviewed send back ''
Select count(*) into modcnt FROM DECREVIEW
  WHERE folder = infolder and issue = inissue and modtime is not null;
if modcnt = 0 then
  RETURN '';
end if;

select   nvl(length(EX1), 0 ) +
         nvl(length(EX2), 0 ) +
         nvl(length(EX3), 0 ) +
         nvl(length(EX4), 0 ) +
         nvl(length(EX5), 0 ) +
         nvl(length(EX6), 0 ) +
         nvl(length(EX7), 0 ) +
         nvl(length(EX8), 0 ) +
         nvl(length(EX9), 0 ) +
         nvl(length(EX10), 0 ) +
         nvl(length(EX11), 0 ) +
         nvl(length(EX12), 0 ) +
         nvl(length(EX13), 0 ) +
         nvl(length(EX14), 0 ) +
         nvl(length(EX15), 0 ) +
         nvl(length(EX16), 0 ) +
         nvl(length(EX17), 0 ) +
         nvl(length(EX18), 0 ) +
         nvl(length(EX19), 0 ) +
         nvl(length(EX20), 0 ) +
         nvl(length(EX21), 0 ) +
         nvl(length(EX22), 0 ) +
         nvl(length(EX23), 0 ) +
         nvl(length(EX24), 0 ) +
         nvl(length(EX25), 0 ) +
         nvl(length(EX26), 0 ) +
         nvl(length(EX27), 0 ) +
         nvl(length(EX28), 0 ) +
         nvl(length(EX29), 0 ) +
         nvl(length(EX30), 0 ) +
         nvl(length(EX31), 0 ) +
         nvl(length(EX32), 0 ) +
         nvl(length(EX33), 0 ) +
         nvl(length(EX34), 0 ) +
         nvl(length(EX35), 0 ) +
         nvl(length(EX36), 0 ) +
         nvl(length(EX37), 0 ) +
         nvl(length(EX38), 0 )
     into excnt FROM DECREVIEW
     WHERE folder = infolder and issue = inissue ;

if excnt > 0 then
  exyn := 'Y';
else
  exyn := 'N';
end if;

RETURN exyn;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DECREV_REVDATE" (infolder CHAR)
  RETURN DATE AS revdate DATE;

BEGIN
select max(REVIEW_DATE) into revdate from DECREVIEW
  where folder = infolder;
RETURN revdate;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DIARY_CHECK" (folder CHAR, actcode CHAR)
  RETURN CHAR AS dind varchar2(1);

dcnt number;

BEGIN
-- Pending check
select count(*) into dcnt from assign
 where tsktknm = folder and tskactcd = actcode and tskdcls is null;
if dcnt > 0 then
  RETURN 'P';
end if;

-- Closed Check
select count(*) into dcnt from assign
 where tsktknm = folder and tskactcd = actcode and tskdcls is not null;
if dcnt > 0 then
  RETURN 'C';
end if;

-- No Diary
RETURN ' ';

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DIARY_CNT" (folder CHAR)
  RETURN number AS dcnt number;

BEGIN
select count(*) into dcnt from assign
 where tsktknm = folder and tskactcd like 'VBA%';

RETURN dcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DIARY_CNT_HOLD" (folder CHAR)
  RETURN number AS dcnt number;

BEGIN
select count(*) into dcnt from assign
 where tsktknm = folder and tskdcls is null and
 tskactcd in ('EXT', 'HCL', 'POA');

RETURN dcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DIARY_CNT_OPEN" (folder CHAR)
  RETURN number AS dcnt number;

BEGIN
select count(*) into dcnt from assign
 where tsktknm = folder and tskdcls is null;

RETURN dcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DIARY_DUE" (folder CHAR)
  RETURN DATE AS
  duedate DATE;

BEGIN
select min(TSKDDUE) into duedate from assign where tsktknm = folder and tskdcls is null;
RETURN duedate;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DIARY_DUE_RO" (folder CHAR)
  RETURN char AS adesc varchar2(60);

duedate DATE;
acode varCHAR2(50);

BEGIN
select tskactcd, tskddue into acode, duedate from assign
 where tsktknm = folder and tskdcls is null and tskactcd like 'VBA%' and
 rownum = 1 order by tskddue ASC;

select actcdesc into adesc from actcode
  where actckey = acode;

adesc := to_char(duedate, 'mm/dd/yy') || ' ' || acode || ' ' || adesc;

RETURN adesc;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DIARY_VBA45" (folder CHAR)
  RETURN CHAR AS dind varchar2(1);

dcnt number;

BEGIN
select count(*) into dcnt from assign
 where tsktknm = folder and tskactcd = 'VBA45'
   and tskdcls is null;
if dcnt > 0 then
  RETURN 'Y';
else
  RETURN ' ';
end if;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DISPATCHER_CNT" (logid CHAR)
  RETURN NUMBER AS  actcnt number;

BEGIN
select count(*) into actcnt from BRIEFF where bforgtic = logid and
  bfmpro = 'ACT' and bfcurloc = '30';

RETURN actcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DOCKET_YYMM" (docket CHAR)
  RETURN CHAR AS dockyymm varchar2(7);



BEGIN
if substr(docket,1,2) < '89' and substr(docket,1,2) > '50' then
  return '??/19' || substr(docket,1,2);
end if;

select tkdata into dockyymm from vacols.foldrnum
 where tkkey = 'DN' and tkdata1 =
(select max(tkdata1) from vacols.foldrnum
 where tkkey = 'DN' and tkdata1 <= docket);

if (substr(dockyymm,4,2)) between '00' and '50' then
  dockyymm := substr(dockyymm,1,3) || '20' || substr(dockyymm,4,2);
else
  dockyymm := substr(dockyymm,1,3) || '19' || substr(dockyymm,4,2);
end if;

RETURN dockyymm;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."DUP_DOCKET" (docket CHAR, appealid CHAR)
  RETURN NUMBER AS   dcnt number;

BEGIN

select count(*) into dcnt from folder where  tinum = docket and titrnum <> appealid;

RETURN dcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ECA_REVOC" (folder CHAR)
  RETURN CHAR AS revoc varchar2(3);

eccnt number;
wcnt number;

BEGIN
revoc := '';

select count(*) into eccnt from attach
 where imgtkky = folder and imgdoctp = 'EC';

if eccnt > 0 then
   revoc := 'YES';
end if;

select count(*) into wcnt from assign
 where tsktknm = folder and tskactcd = 'W';

if wcnt > 0 then
   revoc := 'YES';
end if;

RETURN revoc;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."FORMAL_HELD" (folder CHAR)
   RETURN CHAR AS formal varchar2(1);

hrcnt number;

BEGIN
select count(*) into hrcnt from hearsched where folder_nr = folder
and hearing_type = 'F'and hearing_disp = 'H';

if hrcnt > 0 then
   formal := 'Y';
else
   formal := ' ';
end if;

Return formal;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."FORMAL_PENDING" (folder CHAR)
   RETURN CHAR AS formal varchar2(1);

hrcnt number;

BEGIN
select count(*) into hrcnt from hearsched where folder_nr = folder
and hearing_type = 'F'and hearing_disp is null;

if hrcnt > 0 then
   formal := 'Y';
else
   formal := 'N';
end if;

Return formal;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."FY_RETURN" (indate DATE)
  RETURN CHAR AS FY varchar2(2);

cfy number;

BEGIN

if to_char(indate, 'MM') >= '01' and to_char(indate, 'MM') <= '09' then
   FY := to_char(indate, 'YY');
else
   cfy := to_number(to_char(indate, 'YY')) + 1;
   if cfy < 10 then
      FY:= '0' || to_char(cfy);
   elsif cfy = 100 then
      FY:= '00';
   else
      FY := to_char(cfy);
   end if;
end if;

RETURN FY;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_CASE" -- for bfhr = 1 or 2 check if Held, Cancelled or No-Show.  Held include 11/3/16 these now go to Intake
 -- 0 = Hearing case Postponed or pending (no hearing record)
 (folder CHAR)
  RETURN NUMBER AS
  hrcnt number;
BEGIN
select count(*) into hrcnt from hearsched where folder_nr = folder
and hearing_type in ('C', 'T', 'V', 'R') and hearing_disp in ('H', 'C', 'N');
RETURN hrcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_CLARIFICATION" (appealid CHAR, docket CHAR)
  RETURN DATE as hrdate DATE;

CURSOR DN_Cur is
  SELECT IMGADTM FROM ATTACH, FOLDER
   WHERE TICKNUM = IMGTKKY  and
     (TITRNUM = appealid AND (tinum = docket or tinum is null))
     and IMGDOCTP = 'HR' order by IMGADTM DESC;

BEGIN

OPEN DN_Cur;
FETCH DN_Cur into hrdate;
CLOSE DN_Cur;


return hrdate ;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_DATE" (appealid CHAR, docket CHAR)
  RETURN DATE as hrdate DATE;

CURSOR DN_Cur is
  SELECT HEARING_DATE FROM HEARSCHED, FOLDER
   WHERE TICKNUM = FOLDER_NR and
     (TITRNUM = appealid AND (tinum = docket or tinum is null))
     and HEARING_TYPE in ('C', 'T', 'V', 'R') and HEARING_DISP = 'H' order by HEARING_DATE DESC;

BEGIN

OPEN DN_Cur;
FETCH DN_Cur into hrdate;
CLOSE DN_Cur;


return hrdate ;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_DATE_VLJ"
  (appealid CHAR, docket CHAR, vlj CHAR)
  RETURN DATE as hrdate DATE;

CURSOR DN_Cur is
  SELECT HEARING_DATE FROM HEARSCHED, FOLDER
   WHERE TICKNUM = FOLDER_NR and
     (TITRNUM = appealid AND (tinum = docket or tinum is null))
     and HEARING_TYPE in ('C', 'T', 'V', 'R') and board_member = vlj and
     HEARING_DISP = 'H' order by HEARING_DATE DESC;

BEGIN

OPEN DN_Cur;
FETCH DN_Cur into hrdate;
CLOSE DN_Cur;


return hrdate ;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_DISP" (appealid CHAR)
  RETURN CHAR AS  hrinfo varchar2(20);

CURSOR DV_Cur is select hearing_disp || ' ' || to_char(hearing_date, 'mm/dd/yy')
 || ' ' || nvl(aod, 'N')|| ' ' || to_char(holddays, '999')
 into hrinfo from BRIEFF, HEARSCHED where
 bfkey = folder_nr and bfcorlid = appealid
 and hearing_type in ('C', 'T', 'V', 'R') order by hearing_date Desc;

BEGIN

OPEN DV_Cur;
FETCH DV_Cur into hrinfo;
CLOSE DV_Cur;

RETURN hrinfo;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_HELD" (folder CHAR)
  RETURN NUMBER AS
  hrcnt number;
BEGIN
select count(*) into hrcnt from hearsched where folder_nr = folder
and hearing_type in ('C', 'T', 'V', 'R')
and hearing_disp in ('H', 'C', 'N');
RETURN hrcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_HELD2" (folder CHAR)
  RETURN NUMBER AS
  hrcnt number;
BEGIN
select count(*) into hrcnt from hearsched where folder_nr = folder
and hearing_type in ('C', 'T', 'V', 'R')
and hearing_disp in ('H');
RETURN hrcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_HELD_INFO" (appealid CHAR, docket CHAR)
  RETURN CHAR AS hrinfo varchar2(30);

hrtype varchar2(1);
hrdate varchar2(8);
hrmem varchar2(20);


CURSOR DN_Cur is
  SELECT to_char(hearing_date, 'mm/dd/yy'), hearing_type, board_member
   FROM HEARSCHED, FOLDER WHERE TICKNUM = FOLDER_NR and
     (TITRNUM = appealid AND (tinum = docket or tinum is null))
     and HEARING_TYPE in ('C', 'T', 'V', 'R') and HEARING_DISP = 'H'
     order by HEARING_DATE DESC;

BEGIN

OPEN DN_Cur;
FETCH DN_Cur into hrdate, hrtype, hrmem;
CLOSE DN_Cur;

hrinfo := hrtype || ' ' || hrdate || ' ' || hrmem;
return hrinfo ;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_HELD_POSTREM" (folder CHAR, decdate date)
  RETURN char AS held varchar2(1);

hrcnt number;

BEGIN
select count(*) into hrcnt from hearsched where folder_nr = folder
and hearing_type in ('C', 'T', 'V', 'R')
and hearing_disp in ('H', 'C', 'N') and hearing_date > decdate;

if hrcnt > 0 then
  held := 'Y';
else
  held := ' ';
end if;

RETURN held;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_HELD_SCHED" -- Hearing held or Scheduled
  (folder CHAR, reqdate date)
  RETURN DATE AS hrdate date;

BEGIN
select Max(hearing_date) into hrdate from hearsched
  where folder_nr = folder
  and hearing_type in ('C', 'T', 'V', 'R')
  and (hearing_disp = 'H' or hearing_disp = null)
  and (hearing_date > reqdate or reqdate is null);

RETURN hrdate;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_HOLD" (folder CHAR)
 RETURN CHAR AS  hrinfo varchar2(4);

BEGIN
select max(to_char(holddays, '999'))  into hrinfo from hearsched where folder_nr = folder
and hearing_type in ('C', 'T', 'V', 'R')  and hearing_disp in ('H', 'C', 'N');

if hrinfo is null then
  hrinfo := '   ';
end if;

RETURN hrinfo;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_PENDING_ADV"
  (folder CHAR, inhr CHAR, inha CHAR)
  RETURN CHAR AS pending varchar2(1);

hrcnt number;

BEGIN

if inhr <> '1' and inhr <> '2' then
   return 'N';
end if;

if inhr is null then
   return 'N';
end if;

if inha = '1' or inha = '2' or inha = '6' then
   return 'N';
end if;

select count(*) into hrcnt from hearsched where folder_nr = folder
and hearing_type in ('C', 'T', 'V', 'R') and hearing_disp in ('H', 'C', 'N');

if hrcnt > 0 then
  pending := 'N';
else
  Pending := 'Y';
end if;

RETURN pending;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_REPNAME" (folder CHAR)
  RETURN CHAR AS hrrep varchar2(25);

BEGIN
select max(repname) into hrrep  from hearsched where folder_nr = folder
  and hearing_type in ('C', 'T', 'V', 'R') ;

RETURN hrrep;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_SCHEDULED" (folder CHAR)
  RETURN CHAR AS sched varchar2(1);

hrcnt number;

BEGIN
select count(*) into hrcnt from hearsched where folder_nr = folder
  and hearing_type in ('C', 'T', 'V', 'R') and hearing_disp is null;

if hrcnt > 0 then
  sched := 'Y';
else
  sched := '';
end if;

RETURN sched;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_SCHEDULED_INFO" (folder CHAR)
  RETURN CHAR AS hrinfo varchar2(10);

hrtype varchar2(1);
hrdate varchar2(8);

BEGIN
select hearing_type, to_char(hearing_date, 'mm/dd/yy') into hrtype, hrdate
  from hearsched where folder_nr = folder
  and hearing_type in ('C', 'T', 'V', 'R') and hearing_disp is null;

hrinfo := hrtype || ' ' || hrdate;

RETURN hrinfo;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_VENUE" (vdkey CHAR)
  RETURN CHAR AS hrro varchar2(4);

trip   number;
leg    number;
folder   varchar2(12);
seq_nr   number;

BEGIN
-- Travel Board
if substr(vdkey, 5,1) = '-' then

  if substr(vdkey, 7,1) = '-' then
     trip := to_number(substr(vdkey, 6,1));
     leg  := to_number(substr(vdkey, 8,1));
  elsif substr(vdkey, 8,1) = '-' then
     trip := to_number(substr(vdkey, 6,2));
     leg  := to_number(substr(vdkey, 9,1));
  else
     trip := to_number(substr(vdkey, 6,3));
     leg  := to_number(substr(vdkey, 10,1));
  end if;

  select tbro into hrro from tbsched where
   tbyear = substr(vdkey,1,4) and tbtrip = trip and tbleg = leg;

else
-- Video Hearings
  seq_nr := to_number(vdkey);
  select folder_nr into folder
    from hearsched where hearing_pkseq = seq_nr;
  hrro := substr(folder,7,4) ;

end if;


RETURN hrro;
EXCEPTION WHEN VALUE_ERROR THEN RETURN '';

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HEARING_VLJ" (appealid CHAR, docket CHAR)
  RETURN CHAR AS hrinfo varchar2(50);

vlj varchar2(4);
hrtype varchar2(20);
team varchar2(10);

CURSOR DN_Cur is
  SELECT HEARING_TYPE,  BOARD_MEMBER FROM HEARSCHED, FOLDER
   WHERE TICKNUM = FOLDER_NR and
     (TITRNUM = appealid AND (tinum = docket or tinum is null))
     and HEARING_TYPE <> 'F' and HEARING_DISP = 'H' order by HEARING_DATE DESC;

BEGIN

OPEN DN_Cur;
FETCH DN_Cur into hrtype, vlj;
CLOSE DN_Cur;

Select max(smemgrp) into team from Staff where sattyid = vlj;

if hrtype is null then hrtype := ' '; end if;
if vlj is null then vlj := ' '; end if;
if team is null then team := '  '; end if;

if    hrtype = 'C' then hrtype := 'Central Office';
elsif hrtype = 'T' then hrtype := 'Travel Board  ';
elsif hrtype = 'V' then hrtype := 'Video         ';
else  hrtype := ' ';
end if;

return team || ',' || vlj || ',' || hrtype ;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."HRG_SCHED" (folder CHAR)
RETURN CHAR AS tbind varchar2(1);

tbcnt number;

BEGIN
select count(*) into tbcnt from HEARSCHED where folder_nr = folder
  and hearing_type in ('C', 'T', 'V', 'R')
  and (hearing_disp is null or hearing_disp = 'H');

if tbcnt > 0 then
  tbind := 'Y';
else
  tbind := '';
end if;

RETURN tbind ;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."IHP_ATTACHED" (folder1 CHAR)
  RETURN CHAR AS ctyn varchar2(1);

ctcnt number;

BEGIN
select count(*) into ctcnt from attach
 where imgtkky = folder1
 and imgdoctp = 'IH';

if ctcnt > 0 then
  ctyn := 'Y';
else
  ctyn := 'N';
end if;


RETURN ctyn;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."IME_CNT" (folder CHAR)
  RETURN NUMBER AS
  imecnt number;
BEGIN
select count(*) into imecnt from assign
 where tsktknm = folder and
 substr(tskactcd,1,1) in ('1', '2', '3');
RETURN imecnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISDIGITFN" (zip_code CHAR)
  RETURN CHAR AS
  isdigitfn varchar2(5);
BEGIN
if (ascii(zip_code) >= 48 and ascii(zip_code) <= 57) then
    isdigitfn := 'TRUE';
else isdigitfn := 'FALSE';
end if;
RETURN isdigitfn;
END isdigitfn;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_1151_OR_DIC" (folder CHAR, incode CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
-- If incode = 01-1151 Elig then check for 08-DIC and vice versa
-- report needs appeals where both 01 and 08 exist
if incode = '01' then
   select count(*) into isscnt from issues
    where isskey = folder and issdc in ('1', '3', '4') and
     issprog = '02' and isscode = '08';
else
   select count(*) into isscnt from issues
    where isskey = folder and issdc in ('1', '3', '4') and
     issprog = '02' and isscode = '01';
end if;


RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder;

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_ALLOWED" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and issdc = '1';

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_ALLOWED_NM" (folder CHAR)
  RETURN NUMBER AS   isscnt number;

acnt number;
nmcnt number;

BEGIN
select count(*) into acnt from issues where isskey = folder  and issdc = '1';

select count(*) into nmcnt from issues where isskey = folder
  and issdc = '1' and issprog = '02' and isscode = '15' and isslev1 = '04';

if acnt > 0 and acnt = nmcnt then
  isscnt := 1;
else
  isscnt := 0;
end if;

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_BVA" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and (issdc between '1' and '9' or issdc is null) ;

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_BVADEC" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and issdc between '1' and '9';

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_DENIED" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and issdc = '4';

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_IR_TDIU" (folder CHAR, disp CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and issdc = disp and issprog = '02' and isscode in ('12', '17');

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_OPEN" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and issdc is null;

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_OPEN_CP" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and issdc is null and (issprog = '02' or issprog = '07');

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_OPEN_HRG_LOSS" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and issdc is null and issprog = '02' and isscode = '15'
  and isslev2 in ('6100', '6260');

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_OPEN_OR_REM" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and (issdc = '3' or issdc is null);

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_OPEN_SC_IR" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and issdc is null and issprog = '02' and isscode in ('12', '15');

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_CNT_REMAND" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and issdc = '3';

RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_DISP" (folder CHAR, disp CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and issdc = disp;

if isscnt > 0 then
     Return 1;
else
     Return 0;
end if;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ISSUE_PREF9" -- OGC report d_ogc_29 in datareq.pbl
 (folder CHAR, nod DATE, FORM9 DATE)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder
  and issdcls between nod and form9;

if isscnt > 0 then
     Return 1;
else
     Return 0;
end if;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."MAILACT_PREV" (folder CHAR, actdate DATE)
  RETURN DATE AS prevdate DATE;

CURSOR DV_Cur is SELECT macompdate FROM MAILACT WHERE mafolder = folder
  AND macompdate < actdate order by macompdate DESC;

BEGIN

OPEN DV_Cur;
FETCH DV_Cur into prevdate;
CLOSE DV_Cur;

RETURN prevdate;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."MAILTYPE_CNT" (folder CHAR, mtype CHAR)
  RETURN CHAR AS  rtn CHAR;

mailcnt number;
BEGIN
select count(*) into mailcnt from MAIL where mlfolder = folder and
  mltype = mtype;

if mailcnt > 0 then
   rtn := 'Y';
else
   rtn := 'N';
end if;

RETURN rtn;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."MAILTYPE_OPEN" (folder CHAR, mtype CHAR)
  RETURN NUMBER AS mailcnt number;


BEGIN
select count(*) into mailcnt from MAIL where mlfolder = folder and
  mltype = mtype and mlcompdate is null;


RETURN mailcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."MAIL_CNT" (folder CHAR)
  RETURN NUMBER AS
  mailcnt number;
BEGIN
select count(*) into mailcnt from MAIL where mlfolder = folder and
  mlcompdate is null;

RETURN mailcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."MAIL_CNT_LOC81" (folder CHAR)
  RETURN NUMBER AS
  mailcnt number;
BEGIN
select count(*) into mailcnt from MAIL where mlfolder = folder and
  mlcompdate is null and mltype not in ('02', '05', '08', '13');

RETURN mailcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."MEDISSUE_CNT" (folder CHAR)
  RETURN NUMBER AS
  isscnt number;
BEGIN
select count(*) into isscnt from issues where isskey = folder and issprog = '06';
RETURN isscnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."OTHDOCS_CNT" (folder CHAR)
  RETURN NUMBER AS  othcnt number;

BEGIN
select count(*) into othcnt from OTHDOCS where ticknum = folder;

RETURN othcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."OT_DEC" (folder CHAR)
  RETURN CHAR AS ot varchar2(1);

otcnt number;

BEGIN
ot := 'N';

select count(*) into otcnt from decass
 where defolder = folder and substr(deprod,1,2) = 'OT';

if otcnt > 0 then
   ot := 'Y';
end if;

RETURN ot;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."OVLJ_CNT" (logid CHAR)
  RETURN NUMBER AS  actcnt number;

BEGIN
select count(*) into actcnt from BRIEFF where bforgtic = logid and
  bfmpro = 'ACT' and bfcurloc in ('11', '12');

RETURN actcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PAPERLESS" (folder CHAR)
  RETURN CHAR AS  paperless CHAR;

pcnt number;

BEGIN
select count(*) into pcnt from FOLDER where ticknum = folder
  and (tisubj2 = 'Y' or tivbms = 'Y') ;
if pcnt > 0 then
   paperless := 'Y';
else
   paperless := 'N';
end if;

RETURN paperless;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."POST_HRG_DEC" (appealid CHAR, docket CHAR, hrgdate DATE)
  RETURN DATE AS decdate DATE;

CURSOR DV_Cur is SELECT bfddec FROM BRIEFF, FOLDER WHERE
TICKNUM = BFKEY and (TITRNUM = appealid AND (tinum = docket or tinum is null))
   AND bfddec >= hrgdate and bfdc between '1' and '9' order by bfddec ASC;

BEGIN

OPEN DV_Cur;
FETCH DV_Cur into decdate;
CLOSE DV_Cur;

RETURN decdate;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."POS_LOOKUP" (inkey CHAR)
  RETURN CHAR AS  retpos varchar2(10);

BEGIN
select max(CTYPVAL) into retpos from CORRTYPS where ctypkey = inkey and ctypval like 'PS%' ;

RETURN retpos;
END ;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PREV_APPEALS" -- Previous Appeals with different Docket Number
 (appealid char, form9 date, decdate date)
  RETURN NUMBER AS  prevcnt number;

BEGIN
select count(distinct bfd19) into prevcnt from BRIEFF where bfcorlid = appealid and
    bfddec < decdate and bfd19 <> form9 and bfdc between '1' and '9';

RETURN prevcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PREV_ATTY" (appealid CHAR, docket CHAR)
  RETURN CHAR as attyid VARCHAR2(16);

CURSOR DN_Cur is
  SELECT BFATTID FROM BRIEFF, FOLDER
   WHERE TICKNUM = BFKEY and
     (TITRNUM = appealid AND (tinum = docket or tinum is null))
     and (BFATTID is not null and BFATTID <> '000') order by BFDDEC DESC;

BEGIN

OPEN DN_Cur;
FETCH DN_Cur into attyid;
CLOSE DN_Cur;


return attyid ;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PREV_BVA_DEC"
 (appealid char,  decdate Date)
  RETURN NUMBER AS  deccnt number;

BEGIN
select count(*) into deccnt from BRIEFF where bfcorlid= appealid and
  BFDC between '1' and '9' and BFDDEC < decdate;
RETURN deccnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PREV_REMAND" -- Previous Remand
 (appealid char, form9 date, decdate Date)
  RETURN NUMBER AS  remcnt number;

BEGIN
select count(*) into remcnt from BRIEFF where bfcorlid= appealid and BFD19 = form9 and
  BFAC = '3' and BFDDEC < decdate;
RETURN remcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PREV_VLJ" (appealid CHAR, docket CHAR)
  RETURN CHAR as memid VARCHAR2(16);

CURSOR DN_Cur is
  SELECT BOARD_MEMBER FROM HEARSCHED, FOLDER
   WHERE TICKNUM = FOLDER_NR and
     (TITRNUM = appealid AND (tinum = docket or tinum is null))
     and HEARING_TYPE in ('C', 'T', 'V', 'R') and HEARING_DISP = 'H' order by HEARING_DATE DESC;

CURSOR BF_Cur is
  SELECT BFMEMID FROM BRIEFF, FOLDER
   WHERE TICKNUM = BFKEY and
     (TITRNUM = appealid AND (tinum = docket or tinum is null))
     and (BFATTID is not null and BFMEMID <> '000' and BFMEMID <> '999')
     order by BFDDEC DESC;

BEGIN

OPEN DN_Cur;
FETCH DN_Cur into memid;
CLOSE DN_Cur;

if memid <> '000' and memid <> '999' and memid is not null then
   return memid ;
end if;


OPEN BF_Cur;
FETCH BF_Cur into memid;
CLOSE BF_Cur;

return memid ;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PREV_VLJ_RETIRED" (appealid CHAR, docket CHAR)
  RETURN CHAR as meminfo VARCHAR2(18);

memid varchar2(16);

CURSOR DN_Cur is
  SELECT BOARD_MEMBER FROM HEARSCHED, FOLDER
   WHERE TICKNUM = FOLDER_NR and
     (TITRNUM = appealid AND (tinum = docket or tinum is null))
     and HEARING_TYPE in ('C', 'T', 'V', 'R') and HEARING_DISP = 'H' order by HEARING_DATE DESC;

CURSOR BF_Cur is
  SELECT BFMEMID FROM BRIEFF, FOLDER
   WHERE TICKNUM = BFKEY and
     (TITRNUM = appealid AND (tinum = docket or tinum is null))
     and (BFATTID is not null and BFMEMID <> '000') order by BFDDEC DESC;

BEGIN

OPEN DN_Cur;
FETCH DN_Cur into memid;
CLOSE DN_Cur;

if memid <> '000' and memid <> '999' and memid is not null then
   select SACTIVE || ' ' || SATTYID || ' ' || SLOGID into meminfo
     from STAFF where SATTYID = memid;
   return meminfo ;
end if;


OPEN BF_Cur;
FETCH BF_Cur into memid;
CLOSE BF_Cur;

if memid <> '000' and memid <> '999' and memid is not null then
   select SACTIVE || ' ' || SATTYID || ' ' || SLOGID into meminfo
     from STAFF where SATTYID = memid;
   return meminfo ;
end if;

return memid ;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRE_HEARING" -- Pre-hearing entry to be excluded from the Cap Report
 (folder CHAR)
  RETURN NUMBER AS
  hrcnt number;
BEGIN
select count(*) into hrcnt from hearsched where folder_nr = folder and
  hearing_type in ('C', 'V', 'R') and hearing_date is not null and
  board_member is not null and hearing_disp is null;
RETURN hrcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORDEC_MEMID" (in_ac CHAR, in_vlj CHAR, in_dpdcn DATE,
  in_appealid CHAR, in_tinum CHAR)
  RETURN CHAR AS memid varchar2(20);

hrdate date;
mdate date;

CURSOR Hr_Cur is SELECT BOARD_MEMBER, HEARING_DATE from  HEARSCHED, FOLDER
  where TICKNUM = FOLDER_NR and TITRNUM = in_appealid AND tinum = in_tinum and
      HEARING_DISP = 'H' AND HEARING_TYPE in ('C', 'T', 'V', 'R') and
      (HEARING_DATE >= in_dpdcn or in_dpdcn is null)
      order by HEARING_DATE DESC ;
      
CURSOR Brf_Cur is SELECT BFMEMID from BRIEFF where
  BFCORLID = in_appealid and BFDDEC = in_dpdcn and BFMEMID > '000'
   order by BFDDEC DESC;

BEGIN
if in_ac <> '3' and in_ac <> '7' and in_vlj <> '000' then
   memid := in_vlj;
   return memid;
end if;

OPEN Hr_Cur;
FETCH Hr_Cur into memid, hrdate;
CLOSE Hr_Cur;

if length(memid) > 0 then
  return memid;
end if;

OPEN Brf_Cur;
FETCH Brf_Cur into memid;
CLOSE Brf_Cur;
  
if memid is null or memid = '000' then
 memid := '';
end if;

RETURN memid;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_1ST" (folder CHAR)
RETURN DATE AS prdate DATE;

BEGIN
select min(locdout) into prdate from Priorloc
 where lockey = folder ;

RETURN prdate;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_20" (folder CHAR)
RETURN DATE AS pr20date DATE;

BEGIN
select min(locdout) into pr20date from Priorloc
 where lockey = folder and locstto = '20';

RETURN pr20date;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_55" (folder CHAR)
  RETURN NUMBER AS
  pr55cnt number;
BEGIN
select count(*) into pr55cnt from PRIORLOC where lockey = folder
  and locstto = '55' ;

RETURN pr55cnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_55_OR_81" (folder CHAR, locdate DATE)
  RETURN CHAR AS prevloc varchar2(16);

CURSOR DV_Cur is SELECT LOCSTTO FROM PRIORLOC WHERE LOCKEY = folder
  AND locdout < locdate AND locstto in ('55', '81') order by LOCDOUT DESC;

BEGIN

OPEN DV_Cur;
FETCH DV_Cur into prevloc;
CLOSE DV_Cur;

RETURN prevloc;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_81" (folder CHAR, locdate DATE)
  RETURN CHAR AS prevloc varchar2(16);

CURSOR DV_Cur is SELECT LOCSTTO FROM PRIORLOC WHERE LOCKEY = folder
  AND locdout < locdate order by LOCDOUT DESC;

BEGIN

OPEN DV_Cur;
FETCH DV_Cur into prevloc;
CLOSE DV_Cur;

RETURN prevloc;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_81_AFTER_VSO" (folder CHAR, vsodate DATE)
  RETURN NUMBER AS days number;

sodate date;
pr81date date;

BEGIN
sodate := nvl(vsodate, to_date('01-jan-1995'));

select min(locdout) into pr81date from Priorloc
 where lockey = folder and locstto = '81' AND locdout > sodate;

if pr81date is null then
     Return 0;
else
     Return sysdate - pr81date;
end if;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_81_DATE" (folder CHAR)
  RETURN DATE AS prevdate DATE;

CURSOR DV_Cur is SELECT LOCDOUT FROM PRIORLOC WHERE LOCKEY = folder
  AND locstto = '81'  order by LOCDOUT DESC;

BEGIN

OPEN DV_Cur;
FETCH DV_Cur into prevdate;
CLOSE DV_Cur;

RETURN prevdate;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_901" (folder CHAR)
  RETURN NUMBER AS
  pr901cnt number;
BEGIN
select count(*) into pr901cnt from PRIORLOC where lockey = folder
  and substr(loclcode,4,6) = '901' ;

RETURN pr901cnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_CHARGE" (folder CHAR, curloc CHAR)
  RETURN CHAR AS  prevloc varchar2(16);

CURSOR DV_Cur is SELECT LOCSTTO FROM PRIORLOC WHERE LOCKEY = folder
  AND locstto <> curloc order by LOCDOUT DESC;

BEGIN

OPEN DV_Cur;
FETCH DV_Cur into prevloc;
CLOSE DV_Cur;

RETURN prevloc;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_CHARGE_DATE" (folder CHAR, loc CHAR)
RETURN DATE AS prdate DATE;

BEGIN
select min(locdout) into prdate from Priorloc
 where lockey = folder and locstto = loc ;

RETURN prdate;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_CNT_ADM"
 (folder CHAR, locdate1 DATE, locdate2 DATE)
  RETURN NUMBER AS  prcnt number;

BEGIN
select count(*) into prcnt from PRIORLOC where lockey = folder
  and locdout between locdate1 and locdate2 and
  locstto in ('24', '45', '55', '59', '11', '12', '26', '14', '57' ) ;

RETURN prcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_CNT_AFTER"
 (folder CHAR, locdate DATE)
  RETURN NUMBER AS  prcnt number;

BEGIN
select count(*) into prcnt from PRIORLOC where lockey = folder
  and locdout > locdate ;

RETURN prcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_INIT_ADMIN" (folder CHAR)
RETURN NUMBER AS daycnt NUMBER;

pr01date date;
prnext date;

BEGIN
select min(locdout) into pr01date from Priorloc
 where lockey = folder and locstto = '01';

select min(locdout) into prnext from Priorloc
 where lockey = folder and locstto in ('55', '81');

if prnext > pr01date then
  daycnt := prnext - pr01date;
else
   daycnt := 0;
end if;


RETURN daycnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_LAST" (folder CHAR)
RETURN DATE AS prdate DATE;

BEGIN
select max(locdout) into prdate from Priorloc
 where lockey = folder ;

RETURN prdate;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_PREVCHARGE" (folder CHAR, locdate DATE)
  RETURN CHAR AS prevloc varchar2(16);

prdate date;

CURSOR DV_Cur is SELECT LOCSTTO FROM PRIORLOC WHERE LOCKEY = folder
  AND locdout < prdate order by LOCDOUT DESC;

BEGIN

-- Modified 9/7/17 to use max datetime in priorloc for VLJ Assigned rpt
-- instead of the date passed (which didn't include the time)
select max(locdout) into prdate from Priorloc
 where lockey = folder ;


OPEN DV_Cur;
FETCH DV_Cur into prevloc;
CLOSE DV_Cur;

RETURN prevloc;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PRIORLOC_PREVCHARGE2" (folder CHAR, locdate DATE)
  RETURN CHAR AS prevloc varchar2(16);


CURSOR DV_Cur is SELECT LOCSTTO FROM PRIORLOC WHERE LOCKEY = folder
  AND locdout < locdate order by LOCDOUT DESC;

BEGIN

OPEN DV_Cur;
FETCH DV_Cur into prevloc;
CLOSE DV_Cur;

RETURN prevloc;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PROGRAM_AREA" (folder CHAR)
  RETURN CHAR AS  pa VARCHAR2(2);

isscnt number;
prgcnt number;

BEGIN
select count(*) into isscnt from issues where isskey = folder;

if isscnt = 0 then
  return null;
end if;

select max(issprog) into pa from issues where isskey = folder;
select count(*) into prgcnt from issues where isskey = folder and issprog = pa;

if isscnt <> prgcnt then
  return 'MP' ;
else
  return pa;
end if;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PTSD_IND" (folder CHAR)
  RETURN CHAR AS  ptsd CHAR;

isscnt number;

BEGIN
select count(*) into isscnt from issues where isskey = folder
  and (isslev2 = '9411' or isslev3 = '9411') ;
if isscnt > 0 then
   ptsd := 'Y';
else
   ptsd := 'N';
end if;

RETURN ptsd;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PTSD_PENDING" (folder CHAR)
  RETURN CHAR AS  ptsd CHAR;

isscnt number;

BEGIN
select count(*) into isscnt from issues where isskey = folder
  and (isslev2 = '9411' or isslev3 = '9411') and issdcls is null ;
if isscnt > 0 then
   ptsd := 'Y';
else
   ptsd := 'N';
end if;

RETURN ptsd;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."PTSD_REM" (folder CHAR)
  RETURN CHAR AS  ptsd CHAR;

isscnt number;

BEGIN
select count(*) into isscnt from issues where isskey = folder
  and (isslev2 = '9411' or isslev3 = '9411') and issdc = '3';
if isscnt > 0 then
   ptsd := 'Y';
else
   ptsd := 'N';
end if;

RETURN ptsd;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."REM_GRANT_WD" --  Remand Granted or Withdrawn
 (appealid char, form9 date, decdate Date)
  RETURN NUMBER AS  remcnt number;

BEGIN
select count(*) into remcnt from BRIEFF where bfcorlid = appealid and BFD19 = form9 and
   BFDDEC >= decdate and bfdc in ('B', 'W');
RETURN remcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."REP_CODE" (represent_code CHAR)
  RETURN CHAR AS
  rep_code varchar2(15);
BEGIN
if (represent_code = 'A') then
    rep_code := 'American Legion';
elsif (represent_code = 'B') then
    rep_code := 'AmVets';
elsif (represent_code = 'C') then
    rep_code := 'ARC';
elsif (represent_code = 'D') then
    rep_code := 'DAV';
elsif (represent_code = 'E') then
    rep_code := 'JWV';
elsif (represent_code = 'F') then
    rep_code := 'MOPH';
elsif (represent_code = 'G') then
    rep_code := 'PVA';
elsif (represent_code = 'H') then
    rep_code := 'VFW';
elsif (represent_code = 'I') then
    rep_code := 'State Svc Org';
elsif (represent_code = 'J' or represent_code = 'K' or
       represent_code = 'M' or represent_code = 'N' or
       represent_code = 'O' or represent_code = 'P' or
       represent_code = 'Q' or represent_code = 'R' or
       represent_code = 'S' or represent_code = 'W' or
       represent_code = 'X' or represent_code = 'Y' or
       represent_code = 'Z') then
    rep_code := 'Other Service';
elsif (represent_code = 'L') then
    rep_code := 'None';
elsif (represent_code = 'T') then
    rep_code := 'Attorney';
elsif (represent_code = 'U') then
    rep_code := 'Agent';
elsif (represent_code = 'V') then
    rep_code := 'VVA';
end if;
RETURN rep_code;
END rep_code;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."REVIEWER_CNT" (logid CHAR)
  RETURN NUMBER AS  revcnt number;

advcnt number;
remcnt number;
actcnt number;

BEGIN
select count(*) into advcnt from BRIEFF where bforgtic = logid and
  bfmpro = 'ADV' and bfcurloc = '78';

select count(*) into remcnt from BRIEFF where bforgtic = logid and
  bfmpro = 'REM' and bfcurloc = '96';

select count(*) into actcnt from BRIEFF where bforgtic = logid and
  bfmpro = 'ACT' and bfcurloc = '03';

revcnt := advcnt + remcnt + actcnt;

RETURN revcnt;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ROCDOC_POST_DECISION" (in_ddec DATE,
  in_appealid CHAR, in_status CHAR, in_ac CHAR)
  RETURN CHAR AS disp varchar2(1);

actcnt number;
reremcnt number;
dc char;

BEGIN
-- Original Remands at AMC
if in_status = 'REM' and in_ac = '1' then
   return 'R';
end if;

-- Post-Remands Active at BVA
select count(*) into actcnt from BRIEFF where bfcorlid = in_appealid and
  bfdpdcn = in_ddec and bfac = '3' and bfmpro = 'ACT';
if actcnt > 0 then
   return 'A';
end if;

-- Post-Remands remanded a 2nd time to AMC
select count(*) into reremcnt from BRIEFF where bfcorlid = in_appealid and
  bfdpdcn = in_ddec and bfac = '3' and bfddec > in_ddec and bfmpro = 'REM';
if reremcnt > 0 then
  return 'P';
end if;

-- Disposition of Post-Remand HIS record
select bfdc into dc from BRIEFF where bfcorlid = in_appealid and
  bfdpdcn = in_ddec and bfac = '3' and bfddec > in_ddec and bfmpro = 'HIS';

RETURN dc;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."ROSTAFF_LOOKUP" (domainid CHAR)
  RETURN CHAR AS userid varchar2(20);

BEGIN
select min(rouserid) into userid from
  ROSTAFF where rodomainid = domainid and roactive = 'A';

if userid is null then
   userid := '';
end if;

RETURN userid;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."RO_REMAND" (folder CHAR)
  RETURN NUMBER AS
  rocnt number;
BEGIN
select count(*) into rocnt from priorloc where lockey = folder
and locstto in ('50', '70');
RETURN rocnt;
END RO_REMAND;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."RR_CHECK" (folder CHAR)
  RETURN CHAR AS  rr VARCHAR2(2);

precnt number;
stegallcnt number;

BEGIN
select count(*) into precnt from RMDREA where rmdkey = folder
  and rmddev = 'R1';
select count(*) into stegallcnt from RMDREA where rmdkey = folder
  and rmdval = 'EI';

if precnt > 0 then
   rr := 'Y';
else
   rr := 'N';
end if;

if stegallcnt > 0 then
   rr := rr || 'Y';
else
   rr := rr || 'N';
end if;

RETURN rr;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."RR_CHECK_RD" (folder CHAR)
  RETURN CHAR AS  rr VARCHAR2(2);

precnt number;
postcnt number;

BEGIN
select count(*) into precnt from RMDREA where rmdkey = folder
  and rmddev = 'R1';
select count(*) into postcnt from RMDREA where rmdkey = folder
  and rmddev = 'R2';

if precnt > 0 then
   rr := 'Y';
else
   rr := ' ';
end if;

if postcnt > 0 then
   rr := rr || 'Y';
else
   rr := rr || ' ';
end if;

RETURN rr;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."RR_HEARING" (folder CHAR)
  RETURN CHAR AS  rr VARCHAR2(1);

hrcnt number;

BEGIN
select count(*) into hrcnt from RMDREA where rmdkey = folder
  and rmdval = 'EA';

if hrcnt > 0 then
   rr := 'Y';
else
   rr := 'N';
end if;

RETURN rr;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."RR_LOOKUP" (inkey CHAR)
  RETURN CHAR AS  vfdesc varchar2(100);

BEGIN
select FTDESC into vfdesc from VFTYPES where ftkey = inkey;

RETURN vfdesc;
END ;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."RR_NONHEARING" (folder CHAR)
  RETURN CHAR AS  rr VARCHAR2(1);

hrcnt number;

BEGIN
select count(*) into hrcnt from RMDREA where rmdkey = folder
  and rmdval <> 'EA';

if hrcnt > 0 then
   rr := 'Y';
else
   rr := 'N';
end if;

RETURN rr;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."SATTYID_LNAME" (atty CHAR)
  RETURN CHAR AS lname varchar2(60);

BEGIN
select max(SNAMEL) into lname from STAFF where SATTYID = atty ;

if lname is null then
   lname := '';
end if;

RETURN lname;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."SATTYID_LOOKUP" (atty CHAR)
  RETURN CHAR AS userid varchar2(16);

BEGIN
select SLOGID into userid from STAFF where SATTYID = atty ;

if userid is null then
   userid := '';
end if;

RETURN userid;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."TB_SCHED" (folder CHAR)
RETURN CHAR AS tbind varchar2(1);

tbcnt number;

BEGIN
select count(*) into tbcnt from HEARSCHED where folder_nr = folder
  and hearing_type in ('T', 'V', 'R')
  and (hearing_disp is null or hearing_disp = 'H');

if tbcnt > 0 then
  tbind := 'Y';
else
  tbind := '';
end if;

RETURN tbind ;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."TRANS_ATTACHDATE" (folder CHAR)
   RETURN DATE AS prevdate DATE;

atdate date;

CURSOR AT_Cur is select imgadtm from attach
 where imgtkky = folder and imgdoctp = 'CT' order by imgadtm DESC;

BEGIN

OPEN AT_Cur;
FETCH AT_Cur into atdate;
CLOSE AT_Cur;

RETURN atdate;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."TRANS_ATTACHED" (folder1 CHAR)
  RETURN CHAR AS ctyn varchar2(1);

ctcnt number;

BEGIN
select count(*) into ctcnt from attach
 where imgtkky = folder1
 and imgdoctp = 'CT';

if ctcnt > 0 then
  ctyn := 'Y';
else
  ctyn := 'N';
end if;


RETURN ctyn;
END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."TRANS_DATE" (appealid CHAR, docket CHAR)
  RETURN DATE as ctdate DATE;

CURSOR DN_Cur is
  SELECT IMGADTM FROM ATTACH, FOLDER
   WHERE TICKNUM = IMGTKKY and
     (TITRNUM = appealid AND (tinum = docket or tinum is null))
     and IMGDOCTP = 'CT' order by IMGADTM DESC;

BEGIN

OPEN DN_Cur;
FETCH DN_Cur into ctdate;
CLOSE DN_Cur;


return ctdate ;

END;
/


  CREATE OR REPLACE FUNCTION "VACOLS_TEST"."VD_CNT" (in_key CHAR)
  RETURN NUMBER AS
  vdcnt number;
BEGIN
select count(*) into vdcnt from HEARSCHED where vdkey = in_key
  and (hearing_disp is null or hearing_disp = 'H');

RETURN vdcnt ;
END;
/
