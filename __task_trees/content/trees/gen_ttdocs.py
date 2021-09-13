#!/usr/bin/env python3

colors={
# grey
"RootTask": "#eeeeee",
"TrackVeteranTask": "#cccccc",
"DistributionTask": "#dddddd",

# random, sorted by frequency
"BvaDispatchTask": "#e78ac3",
"HearingTask": "#a6d854",
"ScheduleHearingTask": "#ffd92f",
"JudgeDecisionReviewTask": "#e5c494",
"JudgeAssignTask": "#b3b3b3",
"InformalHearingPresentationTask": "#a1c9f4",
"AttorneyTask": "#ffb482",
"EvidenceSubmissionWindowTask": "#8de5a1",
"EvidenceOrArgumentMailTask": "#ff9f9b",
"HearingAdminActionVerifyAddressTask": "#d0bbff",
"AssignHearingDispositionTask": "#debb9b",
"TimedHoldTask": "#fab0e4",
"TranscriptionTask": "#cfcfcf",
"AodMotionMailTask": "#fffea3",
"QualityReviewTask": "#b9f2f0",
"HearingRelatedMailTask": "#ff7f0e",
"StatusInquiryMailTask": "#e377c2",
"TranslationTask": "#bcbd22",
"AttorneyRewriteTask": "#17becf",
"OtherColocatedTask": "#f77189",
"IhpColocatedTask": "#f77183",
"FoiaTask": "#f7727c",
"AppealWithdrawalMailTask": "#f77375",
"VeteranRecordRequest": "#f7736e",
"SendCavcRemandProcessedLetterTask": "#f77465",
"CongressionalInterestMailTask": "#f7755b",
"SpecialCaseMovementTask": "#f7754f",
"CavcRemandProcessedLetterResponseWindowTask": "#f87640",
"ExtensionRequestMailTask": "#f57832",
"PowerOfAttorneyRelatedMailTask": "#ef7d32",
"MissingRecordsColocatedTask": "#ea8032",
"FoiaColocatedTask": "#e58432",
"ReconsiderationMotionMailTask": "#e08632",
"FoiaRequestMailTask": "#dc8932",
"ChangeHearingDispositionTask": "#d88b32",
"CavcTask": "#d48d32",
"JudgeDispatchReturnTask": "#d08f32",
"ScheduleHearingColocatedTask": "#cc9132",
"PoaClarificationColocatedTask": "#c99232",
"ChangeHearingRequestTypeTask": "#c69432",
"HearingClarificationColocatedTask": "#c39532",
"DocketSwitchGrantedTask": "#c09632",
"ExtensionColocatedTask": "#bc9732",
"DocketSwitchMailTask": "#b99932",
"OtherMotionMailTask": "#b69a32",
"DeathCertificateMailTask": "#b39b32",
"JudgeQualityReviewTask": "#b09c32",
"CavcCorrespondenceMailTask": "#ae9d31",
"NoShowHearingTask": "#aa9e31",
"VacateMotionMailTask": "#a79f31",
"AddressChangeMailTask": "#a4a031",
"ReturnedUndeliverableCorrespondenceMailTask": "#a1a131",
"AttorneyQualityReviewTask": "#9ea231",
"DocketSwitchRulingTask": "#9ba331",
"HearingAdminActionForeignVeteranCaseTask": "#97a431",
"HearingAdminActionOtherTask": "#93a531",
"AddressVerificationColocatedTask": "#3aa5df",
"StayedAppealColocatedTask": "#3ba4e4",
"MissingHearingTranscriptsColocatedTask": "#3ba3ea",
"PrivacyActRequestMailTask": "#3ca2f1",
"TranslationColocatedTask": "#46a1f4",
"ControlledCorrespondenceMailTask": "#579ff4",
"NewRepArgumentsColocatedTask": "#649df4",
"DocketSwitchDeniedTask": "#6e9bf4",
"ClearAndUnmistakeableErrorMailTask": "#7899f4",
"PrivacyActTask": "#8197f4",
"AojColocatedTask": "#8995f4",
"JudgeAddressMotionToVacateTask": "#9093f4",
"BoardGrantEffectuationTask": "#9791f4",
"Task": "#9e8ef4",
"MdrTask": "#a48cf4",
"AttorneyDispatchReturnTask": "#aa8af4",
"PreRoutingFoiaColocatedTask": "#b088f4",
"HearingAdminActionIncarceratedVeteranTask": "#b685f4",
"PreRoutingTranslationColocatedTask": "#bb82f4",
"UnaccreditedRepColocatedTask": "#c180f4",
"DeniedMotionToVacateTask": "#c67df4",
"RetiredVljColocatedTask": "#cc7af4",
"PendingScanningVbmsColocatedTask": "#d276f4",
"ArnesonColocatedTask": "#d873f4",
"AbstractMotionToVacateTask": "#dd6ef4",
"PrivacyComplaintMailTask": "#e36af4",
"PulacCerulloTask": "#ea65f4",
"HearingAdminActionMissingFormsTask": "#f05ff4",
"PreRoutingMissingHearingTranscriptsColocatedTask": "#f45cf2",
"HearingAdminActionFoiaPrivacyRequestTask": "#f45deb",
"DismissedMotionToVacateTask": "#f55fe6",
"MandateHoldTask": "#f561e0",
"HearingAdminActionVerifyPoaTask": "#f562db"
}

import math
import matplotlib as mpl
color_threshold=150
def isLight(cp_color):
    rgbColor=[int(n*255) for n in cp_color]
    [r,g,b]=rgbColor
    hsp = math.sqrt(0.299 * (r * r) + 0.587 * (g * g) + 0.114 * (b * b))
    if hsp<=color_threshold:
        print(f"Rejecting color: {mpl.colors.rgb2hex(cp_color)}")
    return hsp>color_threshold

def create_colors(n_colors):
    if n_colors==0:
        return []

    cp=sns.color_palette("Set2")
    cp+=sns.color_palette("pastel")
    cp+=sns.color_palette("tab10")
    cp=list(filter(lambda c: isLight(c), cp))

    colorsNeeded = n_colors - len(cp)
    if colorsNeeded>0:
        for n in range(1,10):
            print(f"Creating {colorsNeeded*n} colors")
            cp2=sns.color_palette("husl", n_colors=colorsNeeded*n)
            cp2=list(filter(lambda c: isLight(c), cp2))
            if len(cp2)>=colorsNeeded:
                cp+=cp2
                break

    return list(map(mpl.colors.rgb2hex, cp))

import seaborn as sns
def gen_colors(inputfile):
    """
    Use this function to create the colors dict above.
    """

    global colors

    typenames={}
    numappeals=0
    with open(inputfile) as jf:
        for linenum,line in enumerate(jf):
            try:
                linedata = json.loads(line)
                numappeals+=1
                for t in linedata['tasks']:
                    count=typenames.get(t['type'],0)
                    typenames[t['type']]=count+1
            except:
                print(f"Unexpected error at line {linenum}", line, sys.exc_info()[0])

    numtasks=sum(count for task,count in typenames.items())
    sortednames=sorted(typenames.items(), key = lambda kv:(kv[1], kv[0]))
    print("numappeals:", numappeals, " numtasks:", numtasks, " tasktypes:", len(sortednames), " colors:", len(colors))
    sortednames.reverse()
    cp=create_colors(len(sortednames)-len(colors))
    i=0
    for name,count in sortednames:
        if name not in colors:
            print("\""+name+"\": \""+cp[i]+"\",")
            colors[name]=cp[i]
        i+=1

def rejectCancelledTasks(linedata):
    return [t for t in linedata['tasks'] if not t['status']=="cancelled"]

def taskToString(task):
    return task['type']+"_"+task['assigned_to_type']

def typesToStringUpTo(i, tcs):
    return ".".join(tcs[0:i+1])

def incrementCount(aDict, key1, key2=None):
    if key2:
        aDict[key1]=aDict.get(key1, {})
        aDict[key1][key2]=aDict[key1].get(key2, 0)+1
    else:
        aDict[key1]=aDict.get(key1,0)+1

import pprint
pp = pprint.PrettyPrinter(indent=4)

def add_appeal_data(linedata):
    tasks=rejectCancelledTasks(linedata)
    tasks.sort(key=lambda t: t['id']) # task.id reflects creation order
    taskMap={ task['id']: task for task in tasks }
    #pp.pprint(tasks)
    #pp.pprint(taskMap)

    taskscreationseq=list(map(taskToString, tasks))
    for i in range(len(taskscreationseq)):
        taskStr=taskscreationseq[i]

        incrementCount(taskCountsDict, taskStr)

        if 'parent_id' in tasks[i] and tasks[i]['parent_id']:
            if tasks[i]['parent_id'] in taskMap:
                parentTaskStr=taskToString(taskMap[tasks[i]['parent_id']])
                incrementCount(parentlinksDict, taskStr, parentTaskStr)
                incrementCount(childlinksDict, parentTaskStr, taskStr)
            else:
                # ignoring cancelled parent tasks.
                pass

        if i>0:
            incrementCount(backlinksDict, taskStr, taskscreationseq[i-1])
        if i+1<len(taskscreationseq):
            incrementCount(nextlinksDict, taskStr, taskscreationseq[i+1])

        typesCreatedPrefix=typesToStringUpTo(i, taskscreationseq)

        tcsSetDict[taskStr]=tcsSetDict.get(taskStr, set())
        tcsSetDict[taskStr].add(typesCreatedPrefix)

        tcsCountsDict[typesCreatedPrefix]=tcsCountsDict.get(typesCreatedPrefix,0)+1

        appealIdsDict[typesCreatedPrefix]=appealIdsDict.get(typesCreatedPrefix, [])
        if(len(appealIdsDict[typesCreatedPrefix])<appealIdsLimit):
            appealIdsDict[typesCreatedPrefix].append(linedata['appeal_id'])
    taskscreationseq

appealIdsLimit=5
appealIdsDict={}
taskCountsDict={}
tcsCountsDict={}
# key=typename values=dict of {key=typesCreatedPrefix(String) value=count}
tcsSetDict={}
nextlinksDict={}
backlinksDict={}
parentlinksDict={}
childlinksDict={}

def clear_data():
    appealIdsDict.clear()
    taskCountsDict.clear()
    tcsCountsDict.clear()
    tcsSetDict.clear()
    nextlinksDict.clear()
    backlinksDict.clear()
    parentlinksDict.clear()
    childlinksDict.clear()

import json
import traceback

def load_data(inputfile, dockettype):
    clear_data()
    #with open('prepped2.json', 'w') as pf:
    with open(inputfile) as jf:
        for count, line in enumerate(jf):
            try:
                linedata = json.loads(line)
                #removeExtraFields(linedata)
                if linedata['docket_type']==dockettype:
                    taskscreationseq=add_appeal_data(linedata)
                #print(count, linedata['appeal_id'], taskscreationseq)
                #pf.write(json.dumps(taskscreationseq)+"\n")
            except Exception as err:
                print(f"Unexpected error at input line {count+1}:", type(err), err.args)
                #traceback.print_exc()
                raise err

def gen_graphviz(dotConfig, toLinksDict, fromLinksDict, *tasknames):
    edges=[]
    for taskname in tasknames:
        if taskname in toLinksDict:
            for link,count in sorted(toLinksDict[taskname].items(), key=lambda kv: (kv[1], kv[0]), reverse=True):
                edges.append(f'"{taskname}" -> "{link}" [label={count}]')
        if taskname in fromLinksDict:
            for link,count in sorted(fromLinksDict[taskname].items(), key=lambda kv: (kv[1], kv[0]), reverse=True):
                edges.append(f'"{link}" -> "{taskname}" [label={count}]')
    if not dotConfig:
        dotConfig = ""
    return wrap_for_graphviz("rankdir=LR;\n"+dotConfig, edges)

def gen_graphviz_mermaid(dotConfig, toLinksDict, fromLinksDict, *tasknames):
    edges=[]
    for taskname in tasknames:
        if taskname in toLinksDict:
            for link,count in sorted(toLinksDict[taskname].items(), key=lambda kv: (kv[1], kv[0]), reverse=True):
                edges.append(f'{taskname} -- {count} --> {link}')
        if taskname in fromLinksDict:
            for link,count in sorted(fromLinksDict[taskname].items(), key=lambda kv: (kv[1], kv[0]), reverse=True):
                edges.append(f'{link} -- {count} --> {taskname}')
    if not dotConfig:
        dotConfig = ""
    return wrap_for_graphviz_mermaid("flowchart LR\n"+dotConfig, edges)

def save_graphviz(basedir, nextlinksDict, backlinksDict, *tasknames):
    tcsName=abbrev(".".join(tasknames))
    os.path.isdir(f'{basedir}/dot/{tcsName}') or os.mkdir(f'{basedir}/dot/{tcsName}')
    with open(f'{basedir}/dot/{tcsName}/{tcsName}.dot', 'w') as gvf:
        gvf.write(gen_graphviz(None, nextlinksDict, backlinksDict, *tasknames))

def gen_plantuml(appeal, highlighttype=""):
    pstr = """@startuml
skinparam {
  ObjectBorderColor #555
  ObjectBorderThickness 0
  ObjectFontStyle bold
  ObjectFontSize 14
  ObjectAttributeFontColor #333
  ObjectAttributeFontSize 12
}
"""
    taskId2LabelDict={}
    sortedTasks=sorted(appeal['tasks'], key=lambda t: t['id'])
    for task in sortedTasks:
        taskLabel=f"{len(taskId2LabelDict)}.{task['type']}"
        taskId2LabelDict[task['id']]=taskLabel
        pstr+=f"  object {taskLabel} {colors[task['type']]}"
        pstr+=" {\n"
        pstr+=task['assigned_to_type']
        if task['type']+"_"+task['assigned_to_type']==highlighttype:
            pstr+=f"  <back:white>    </back>"
        pstr+="\n}\n"
    for task in sortedTasks:
        if task['parent_id']:
            pstr+=f"{taskId2LabelDict.get(task['parent_id'])} -- {taskId2LabelDict[task['id']]}\n"
    pstr+="@enduml\n"
    return pstr

mermaidShapeDict = {
    "RootTask": ["(", ")"],
    "TrackVeteranTask": ["([", "])"],
    "HearingTask": ["[[", "]]"],
    "InformalHearingPresentationTask": ["[/", "\\]"],
    "EvidenceSubmissionWindowTask": ["[/", "/]"],
    "DistributionTask": [">", "]"],
    "JudgeAssignTask": ["[\\", "/]"],
    "JudgeDecisionReviewTask": ["[[", "]]"],
    "QualityReviewTask": ["[\\", "\\]"],
    "BvaDispatchTask": ["{{", "}}"],
    "RootTask": ["([", "])"],
}
def gen_mermaid(appeal, highlighttype=""):
    pstr = "{{< mermaid >}}\nflowchart TD\n"
    taskId2LabelDict={}
    sortedTasks=sorted(appeal['tasks'], key=lambda t: t['id'])
    for task in sortedTasks:
        taskLabel=f"{len(taskId2LabelDict)}.{task['type']}"
        taskId2LabelDict[task['id']]=taskLabel
        pstr+=f"style {taskLabel} fill:{colors[task['type']]}"
        if task['assigned_to_type']=="Organization":
            pstr+=",stroke-dasharray: 5 5"
        if task['type']+"_"+task['assigned_to_type']==highlighttype:
            pstr+=",stroke:#00f,stroke-width:4px"
        pstr+="\n"
        shapeBegin, shapeEnd=mermaidShapeDict.get(task['type'], ["[", "]"])
        pstr+=f"  {taskLabel}{shapeBegin}\"{taskLabel}\\n({task['assigned_to_type'].lower()})\"{shapeEnd}\n"
    pstr+="\n"
    for task in sortedTasks:
        if task['parent_id']:
            pstr+=f"{taskId2LabelDict.get(task['parent_id'])} --> {taskId2LabelDict[task['id']]}\n"
    pstr+="{{< /mermaid >}}\n"
    return pstr

import re
import sys

def find_appeal(inputfile, appeal_id):
    with open(inputfile, "r") as f:
        for count, line in enumerate(f):
            if re.search(f"\"appeal_id\":{appeal_id},", line):
                appeal = json.loads(line)
                return appeal

abbrevCounter = 0
def abbrev(tcs):
    abbrev = ''.join(filter(lambda x: x.isupper() or x=='.', str(tcs)))

    # abbrev can't be too long because it's used as a filename
    global abbrevCounter
    if len(abbrev) > 200:
        abbrev=abbrev[0:190] + "__" +str(abbrevCounter)
        abbrevCounter += 1
    return abbrev

def create_tasklist(basedir, dockettype):
    with open(f'{basedir}/tasklist.md', 'w') as tlf:
        tlf.write("---\n---\n<!-- DO NOT EDIT THIS FILE.  This file is autogenerated. -->\n")
        tlf.write(f'| [Task Listing for All Dockets](../alltasks.md) |\n\n')
        tlf.write(f'# Task Listing for "{dockettype}" Docket\n\n')
        for taskname,tcsSet in tcsSetDict.items():
            subtotal=sum([tcsCountsDict[tcs] for tcs in tcsSet])
            if taskCountsDict[taskname]!=subtotal:
                print("WARN: Expecting to be equal:", taskCountsDict[taskname], subtotal)
        for taskname,count in sorted(taskCountsDict.items(), key=lambda kv: kv[1], reverse=True):
            tlf.write(f'   * [{taskname}]({taskname}.md) ({count} occurrences)\n')

countChartType = "mermaid"
def gen_md_files(inputfile, basedir, dockettype):
    print(f'\nCreating md files and associated dot and uml files under {basedir}')
    for taskname,tcsSet in sorted(tcsSetDict.items(), key=lambda kv: kv[0]):
        #print(task, tcsSet)
        print(f'Creating {basedir}/{taskname}.md')
        with open(f'{basedir}/{taskname}.md', 'w') as mdf:
            mdf.write("---\n---\n<!-- DO NOT EDIT THIS FILE.  This file is autogenerated. -->\n")
            #mdf.write('# '+taskname.split("_")[0]+" "+taskname.split("_")[1]+'\n\n')
            mdf.write(f'| [All Tasks](../alltasks.md) | [{dockettype} Tasks](tasklist.md) |\n\n')
            mdf.write(f'# {taskname} for {dockettype}\n\n')

            mdf.write(f'[{taskname} description](../task_descr/{taskname}.md)\n\n')
            descfile=f'task_descr/{taskname}.md'
            if not os.path.exists(descfile):
                with open(descfile, 'w+') as descrf:
                    descrf.write('| [Tasks Overview](../tasks-overview.md) | [All Tasks](../alltasks.md) | [DR tasks](../docket-DR/tasklist.md) | [ES tasks](../docket-ES/tasklist.md) | [H tasks](../docket-H/tasklist.md) |\n')
                    descrf.write(f'# {taskname} Description\n\n')
                    descrf.write(f'Task stats [for DR](../docket-DR/{taskname}.md), [for ES](../docket-ES/{taskname}.md), [for H](../docket-H/{taskname}.md) dockets.\n\n')

            mdf.write(f'## Parent and Child Tasks\n\n')
            if countChartType == "mermaid":
                mdf.write(gen_graphviz_mermaid(None, childlinksDict, parentlinksDict, taskname))
            else:
                mdf.write(f"<details><summary>Parent and child tasks of {taskname}\n</summary>\n\n```\n")
                graphviz=gen_graphviz("node [shape=box]", childlinksDict, parentlinksDict, taskname)
                mdf.write(graphviz)
                mdf.write('```\n</details>\n\n')
                mdf.write(f'![{taskname}]({taskname}-parentchild.dot.png)\n\n')
                os.path.isdir(f'{basedir}/dot/{taskname}') or os.mkdir(f'{basedir}/dot/{taskname}')
                with open(f'{basedir}/dot/{taskname}/{taskname}-parentchild.dot', 'w') as gvf:
                    gvf.write(graphviz)

            mdf.write('**Parent Tasks:**\n\n')
            if taskname in parentlinksDict:
                for link,count in sorted(parentlinksDict[taskname].items(), key=lambda kv: kv[1], reverse=True):
                    mdf.write(f"   * [{link}]({link}.md): {count} times\n")
            else:
                mdf.write(f"   * (No parent tasks)\n")
            mdf.write("\n")
            mdf.write('**Child Tasks:**\n\n')
            if taskname in childlinksDict:
                for link,count in sorted(childlinksDict[taskname].items(), key=lambda kv: kv[1], reverse=True):
                    mdf.write(f"   * [{link}]({link}.md): {count} times\n")
            else:
                mdf.write(f"   * (No child tasks)\n")
            mdf.write("\n")

            mdf.write(f'## Tasks Created Before and After\n\n')
            if countChartType == "mermaid":
                mdf.write(gen_graphviz_mermaid(None, nextlinksDict, backlinksDict, taskname))
            else:
                mdf.write(f"<details><summary>Tasks created before and after {taskname}</summary>\n\n```\n")
                graphviz=gen_graphviz(None, nextlinksDict, backlinksDict, taskname)
                mdf.write(graphviz)
                mdf.write('```\n</details>\n\n')
                mdf.write(f'![{taskname}]({taskname}.dot.png)\n\n')
                with open(f'{basedir}/dot/{taskname}/{taskname}.dot', 'w') as gvf:
                    gvf.write(graphviz)

            mdf.write('**Before:**\n\n')
            if taskname in backlinksDict:
                for link,count in sorted(backlinksDict[taskname].items(), key=lambda kv: kv[1], reverse=True):
                    mdf.write(f"   * [{link}]({link}.md): {count} times\n")
            else:
                mdf.write(f"   * (No tasks are created before this one)\n")
            mdf.write("\n")
            mdf.write('**After:**\n\n')
            if taskname in nextlinksDict:
                for link,count in sorted(nextlinksDict[taskname].items(), key=lambda kv: kv[1], reverse=True):
                    mdf.write(f"   * [{link}]({link}.md): {count} times\n")
            else:
                mdf.write(f"   * (No tasks are created after this one)\n")
            mdf.write("\n")

            mdf.write('## Task Creation Sequences\n\n')
            subtotal=sum([tcsCountsDict[tcs] for tcs in tcsSet])
            mdf.write(f'There are {subtotal} total occurrences of {taskname} among appeals in the {dockettype} docket.  '+
                'This count includes multiple occurrences in a single appeal.\n\n')
            mdf.write(f'The following subsections provide TCSs up to {taskname}, sorted by frequency.\n\n')
            tcsCount = 0
            for tcs in sorted(tcsSet, key=lambda k: (tcsCountsDict[k], 1000-len(k)), reverse=True):
                # limit the number of tcs subsections
                if tcsCount<10 or (tcsCountsDict[tcs]/subtotal) > .1:
                    mdf.write(gen_tcs_section(inputfile, basedir, subtotal, taskname, tcs, tcsCountsDict[tcs], appealIdsDict[tcs]))
                    tcsCount+=1

treeMarkupType="mermaid"
def gen_tcs_section(inputfile, basedir, subtotal, taskname, tcs, count, example_appeal_ids):
    tcsName=abbrev(tcs)
    tstr=f"### {tcsName}\n\n"

    # Not being used; so don't created it
    # tstr+=(f'[{tcsName} description](../task_descr/{tcsName}.md)\n\n')
    # print(tcs.count('.'), tcs)
    # if tcs.count('.') <= 3:
    #     descfile=f'task_descr/{tcsName}.md'
    #     #print("Creating", tcs)
    #     if not os.path.exists(descfile):
    #         with open(descfile, 'w+') as descrf:
    #             descrf.write(f'# {tcsName} Description\n\n')

    appealId=appealIdsDict[tcs][0]
    appeal=find_appeal(inputfile, appealId)
    percent=count/subtotal
    tstr+=f"{count} ({'{:.0%}'.format(percent)}) occurrences (example appeal IDs: {example_appeal_ids})\n\n"

    if treeMarkupType=="mermaid":
        tstr+=f"Task Tree for appeal with ID {appealId}\n"
        tstr+=gen_mermaid(appeal, taskname)
        tstr+='\n\n'
    else:
        tstr+=f"<details><summary>Task Tree for appeal with ID {appealId}</summary>\n\n```\n"
        plantuml=gen_plantuml(appeal, taskname)
        tstr+=plantuml
        tstr+='```\n</details>\n\n'

        tstr+=f'![{tcsName}-{appealId}]({tcsName}-{appealId}.png)\n\n'
        # create associated plantUML file to generate png
        os.path.isdir(f'{basedir}/uml/{taskname}') or os.mkdir(f'{basedir}/uml/{taskname}')
        with open(f'{basedir}/uml/{taskname}/{tcsName}-{appealId}.uml', 'w') as umlf:
            umlf.write(plantuml)

    return tstr


import os
def generate_docs(inputfile):
    os.path.isdir('task_descr') or os.mkdir('task_descr')

    dockettypes={ "direct_review":"docket-DR", "evidence_submission":"docket-ES", "hearing":"docket-H" }
    for dockettype,basedir in dockettypes.items():
        load_data(inputfile, dockettype)

        os.path.isdir(basedir) or os.mkdir(basedir)
        if treeMarkupType=="mermaid" or countChartType=="mermaid":
            os.path.isdir(basedir+'/uml') or os.mkdir(basedir+'/uml')
        os.path.isdir(basedir+'/dot') or os.mkdir(basedir+'/dot')
        # os.path.isdir(basedir+'/json') or os.mkdir(basedir+'/json')

        gen_md_files(inputfile, basedir, dockettype)
        create_tasklist(basedir, dockettype)
        extract_freq_TCSs(inputfile, basedir, dockettype)
        extract_freq_parent_child(inputfile, basedir, dockettype)

def create_alltask_list(inputfile):
    taskcountDict={}
    with open(inputfile) as jf:
        for count, line in enumerate(jf):
            try:
                linedata = json.loads(line)
                tasks=rejectCancelledTasks(linedata)
                for task in tasks:
                    incrementCount(taskcountDict, taskToString(task), linedata['docket_type'])
            except Exception as err:
                print(f"Unexpected error at input line {count+1}:", type(err), err.args)
                #traceback.print_exc()
                raise err
    with open(f'alltasks.md', 'w') as tlf:
        tlf.write("---\n---\n<!-- DO NOT EDIT THIS FILE.  This file is autogenerated. -->\n")
        tlf.write("""# Task Listing for All Dockets

See [Tasks Overview](tasks-overview.md) for context.

Table columns:
* **sum** = total occurrences across all docket types
* **DR** = occurrences in **direct_review** docket; [DR tasks](docket-DR/tasklist.md)
* **ES** = occurrences in **evidence_submission** docket; [ES tasks](docket-ES/tasklist.md)
* **H** = occurrences in **hearing** docket; [H tasks](docket-H/tasklist.md)

These counts include multiple occurrences in a single appeal.

| Task | sum | DR | ES | H |
| ---- | --- | -- | -- | - |
""")
        listing={}
        for taskname,docket_types in taskcountDict.items():
            subtotal=sum([docket_types[type] for type in docket_types])
            listing[taskname]=subtotal
        for taskname,count in sorted(listing.items(), key=lambda kv: kv[1], reverse=True):
            docket_types=taskcountDict[taskname]
            tlf.write(f'| [{taskname}](task_descr/{taskname}.md) | {count} | \
{gen_count_md_for(taskname,docket_types,"direct_review","docket-DR")} | \
{gen_count_md_for(taskname,docket_types,"evidence_submission","docket-ES")} | \
{gen_count_md_for(taskname,docket_types,"hearing","docket-H")} |\n')

def gen_count_md_for(taskname, docket_types, docket_type, subdir):
    if docket_type in docket_types:
        count=docket_types.get(docket_type, 0)
        return f"[{count}]({subdir}/{taskname}.md)"
    else:
        return "0"

tcsFreq=1500
topNTcs=15

def extract_freq_TCSs(inputfile, basedir, dockettype):
    tcsAppealDict={}
    topNCounter=0;
    for tcs,count in sorted(tcsCountsDict.items(), key=lambda kv: kv[1], reverse=True):
        if (topNCounter<topNTcs or count>tcsFreq):
            tcsObj={'tcs': tcs, 'count': count}
            appealId=appealIdsDict[tcs][0]
            tcsAppealDict[appealId]=tcsAppealDict.get(appealId, [])
            tcsAppealDict[appealId].append(tcsObj)
        else:
            break
        topNCounter+=1

    webpage = "freq-taskcreation"
    with open(f'{basedir}/{webpage}.md', 'w+') as tcf:
        tcf.write("---\n---\n<!-- DO NOT EDIT THIS FILE.  This file is autogenerated. -->\n")
        tcf.write(f'''| Frequent TCSs for [DR](../docket-DR/{webpage}.md), [ES](../docket-ES/{webpage}.md), [H](../docket-H/{webpage}.md) |

# Frequent TCSs for '{dockettype}' Docket

A Task Creation Sequence (TCS) is the sequence of task types for an appeal, sorted by creation time.

This page shows TCSs that satisfy either:
* the TCS occurred at least {tcsFreq} times
* or the TCS is in the top {topNTcs} frequent TCSs

The TCSs below are grouped by appeals that exemplify the TCSs.
To investigate further, click on the relevant task in the [task listing for this docket](tasklist.md)
or [All Tasks for all dockets](../alltasks.md)

''')
        counter=0
        for appealId,tcsObjList in sorted(tcsAppealDict.items(), key=lambda kv: kv[1][0]['count'], reverse=True):
            for tcsObj in tcsObjList:
                counter+=1
                tcf.write(f"{counter}. {abbrev(tcsObj['tcs'])}: **{tcsObj['count']} occurrences**, see appeal {appealId} below  \n  ({tcsObj['tcs']})  \n")

            appeal=find_appeal(inputfile, appealId)
            tcf.write(gen_freq_tcs_diagram(tcsObj, appeal, basedir, webpage).replace('\n','\n  ')+'\n')

def gen_freq_tcs_diagram(tcsObj, appeal, basedir, webpage):
    #print(json.dumps(appeal))
    appealId=appeal['appeal_id']
    if treeMarkupType=="mermaid":
        tstr=f"\nTask Tree for appeal {appealId}:\n\n"
        appealId=appeal['appeal_id']
        tstr+=gen_mermaid(appeal)
    else:
        tstr=f"\n<details><summary>Task Tree for appeal {appealId}</summary>\n\n"
        plantuml=gen_plantuml(appeal)
        tstr+=f'![{appealId}]({appealId}.png)\n'
        os.path.isdir(f'{basedir}/uml/{webpage}') or os.mkdir(f'{basedir}/uml/{webpage}')
        with open(f'{basedir}/uml/{webpage}/{appealId}.uml', 'w') as umlf:
            umlf.write(plantuml)

        tstr+=f"\n<details><summary>UML code for task tree for appeal {appealId}</summary>\n\n```\n"
        tstr+=plantuml
        tstr+='```\n</details>\n\n'
        tstr+='</details>\n\n'
    return tstr


parentTaskFreq=100
parentChildFreq=500
parentChildPercent=0.4
def extract_freq_parent_child(inputfile, basedir, dockettype):
    pcList=[]
    for taskname,childDict in childlinksDict.items():
        if taskCountsDict[taskname]>=parentTaskFreq:
            relationsCount=sum(childDict.values())
            for child,count in childDict.items():
                if count>=parentChildFreq or count/relationsCount >= parentChildPercent:
                    percent=count/relationsCount
                    pcList.append({'parent': taskname, 'child': child, 'count': count, 'percent': percent, 'label': "{:.0%}".format(percent)+f" ({count})"})

    with open(f'{basedir}/dot/freq-parentchild.dot', 'w+') as dotf:
        dotf.write(gen_parentchild_graphviz("rankdir=TB;\nnode [shape=box];", pcList, 'parent', 'child', 'count'))

    gen_freq_parentchild_md(basedir, dockettype, pcList)

def gen_freq_parentchild_md(basedir, dockettype, pcList):
    with open(f'{basedir}/freq-parentchild.md', 'w+') as pcf:
        pcf.write("---\n---\n<!-- DO NOT EDIT THIS FILE.  This file is autogenerated. -->\n")
        pcf.write(f'''| Frequent Parent-Child Relationships for [DR](../docket-DR/freq-parentchild.md), [ES](../docket-ES/freq-parentchild.md), [H](../docket-H/freq-parentchild.md) |

# Frequent Parent-Child Relationships for '{dockettype}'

For this page, *frequent* is defined as (1) the parent task type occurred at least {parentTaskFreq} times and (2) either
* the parent-child relationship occurred at least {parentChildFreq} times (**Count** column)
* or among all parent-child relationships with the same parent task type, at least {round(parentChildPercent*100)}% had the specific child task type (**Percent** column)

Here is a diagram of the frequent parent-child relationships:

![freq-parentchild.dot.png](freq-parentchild.dot.png)

| Parent Task Type | Child Task Type | Count | Percent |
| ---------------- | --------------- | ----- | ------- |
''')
        for edge in sorted(pcList, key=lambda kv: kv['count'], reverse=True):
            pcf.write(f"| [{edge['parent']}]({edge['parent']}.md) | [{edge['child']}]({edge['child']}.md) "+
                f"| {edge['count']} | {'{:.0%}'.format(edge['percent'])} |\n")
        pcf.write("{.parentChildTable}\n") # goldmark markdown to set CSS class on table

def gen_parentchild_graphviz(dotConfig, edgesList, fromKey="from", toKey="to", sortKey="sort", edgeLabelKey="label", sortReverse=True):
    edges=[]
    for edge in sorted(edgesList, key=lambda kv: kv[sortKey], reverse=sortReverse):
        edges.append(f'"{edge[fromKey]}" -> "{edge[toKey]}" [label="{edge[edgeLabelKey]}"]')
    return wrap_for_graphviz(dotConfig, edges)

def wrap_for_graphviz(dotConfig, edges):
    gstr='digraph G {\n'
    if dotConfig:
        gstr+=dotConfig+'\n'
    gstr+="\n".join(edges)
    gstr+="\n}\n"
    return gstr

def wrap_for_graphviz_mermaid(dotConfig, edges):
    gstr='{{< mermaid >}}\n'
    if dotConfig:
        gstr+=dotConfig+'\n'
    gstr+="\n".join(edges)
    gstr+="\n{{< /mermaid >}}\n"
    return gstr

def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <appeals.json>")
        print('''
  For context, see https://github.com/department-of-veterans-affairs/caseflow/issues/12666

  Note that cancelled tasks are ignored when processing the data to reduce noise.

  Use something like the following to get appeal data in json format into a file:

    # suppress output to console
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

    f=File.new('/tmp/appeals-tasks.json', 'w')
    Appeal.where.not(docket_type: nil).each do |a|
      f << "{ \"appeal_id\":#{a.id}, \"docket_type\":\"#{a.docket_type}\", \"updated_at\":\"#{a.updated_at}\", \"tasks\":"+
           a.tasks.order(:created_at, :id).to_json( {only: [:type, :assigned_to_type, :status, :id, :parent_id, :created_at, :updated_at]} )+
           "}\n"
    end; nil
    f.close

    # restore console output
    ActiveRecord::Base.logger = old_logger

  Then move that json file to this directory and run this script with the file as an argument.
  Once the script is completed. Further instructions will be shown to run createPngs.sh.
            ''')
        sys.exit(0)

    print(f'Generating colors for task types in {sys.argv[1]}')
    gen_colors(sys.argv[1])

    print(f'Processing {sys.argv[1]}')
    generate_docs(sys.argv[1])
    create_alltask_list(sys.argv[1])

    print('''
NEXT STEPS:
Run createPngs.sh to convert dot and uml (if any) into images referenced by md files.
If a png file already exists, it will not be recreated, which saves processing time.
If all png files are deleted, recreating the png files will take about several minutes.
''')

if __name__ == "__main__":
    main()
