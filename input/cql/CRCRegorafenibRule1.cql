//大腸直腸_CRCRegorafenib給付規定
library CRCRegorafenibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include CRCCodeConcept version '1.0.0' called CodeConcept

include CRCReusable version '1.0.0' called Reusable
 
context Patient


//============================================
// 主要規定一：初次使用條件
//============================================

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Last(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "本次申請起始日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)




/*規則1*/
//條件1
//Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
define "ICD代碼檢核_布林值": Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

//條件2
define "1規則1-2=癌症分期分數或結果為M≠1":
  Reusable."癌症分期分數或結果為M≠1"

//條件3
define "1規則1-3=三個月內有影像檢查報告":
  Reusable."HasRecentImageReport"(CodeConcept.CetuximabRegorafenibImageReportCode, "本次申請起始日期")

define "1規則1=轉移性大腸直腸癌（mCRC）":
  Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
  and "1規則1-2=癌症分期分數或結果為M≠1"
  and "1規則1-3=三個月內有影像檢查報告"

/*規則2*/
//條件1-1
define "1規則2-1-1=曾接受fluoropyrimidine為基礎的化療":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01EX05, CodeConcept."FluoropyrimidineBase")

//條件1-2
define "1規則2-1-2=曾接受oxaliplatin為基礎的化療":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01EX05, CodeConcept.L01XA03)

//條件1-3
define "1規則2-1-3=曾接受irinotecan為基礎的化療":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01EX05, CodeConcept.L01CE02)

//條件1
define "1規則2-1=曾接受fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療":
  "1規則2-1-1=曾接受fluoropyrimidine為基礎的化療"
  and "1規則2-1-2=曾接受oxaliplatin為基礎的化療"
  and "1規則2-1-3=曾接受irinotecan為基礎的化療"

//條件2
define "1規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01EX05, CodeConcept.L01FG)

define "1規則2=用於治療先前曾接受下列療法的轉移性大腸直腸癌（mCRC）患者，療法包括fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療，和抗血管內皮生長因子(anti-VEGF)等療法；":
  "1規則2-1=曾接受fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療"
  and "1規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法"

/*規則3*/
//條件1
define "1規則3-1=K-ras為原生型(wild type)":
  exists (
    [Observation] RasObs
    where RasObs.status = 'final'
    and exists (
      RasObs.code.coding Cdg
      where Cdg.code = '69548-6'
      and Cdg in CodeConcept.LOINC
    )
    and exists (
      RasObs.interpretation.coding I
      where I.code = 'NEG'
    )
  )

//條件2
define "1規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01EX05, CodeConcept.L01FE)

define "1規則3=若K-ras為原生型(wild type)，需再加上接受過抗表皮生長因子受體（anti-EGFR）療法。":
  not "1規則3-1=K-ras為原生型(wild type)"
  or "1規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法"


define "主要規定一":
  Reusable."初次申請"
  and Reusable."醫令類別為1"
  and "1規則1=轉移性大腸直腸癌（mCRC）"
  and "1規則2=用於治療先前曾接受下列療法的轉移性大腸直腸癌（mCRC）患者，療法包括fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療，和抗血管內皮生長因子(anti-VEGF)等療法；"
  and "1規則3=若K-ras為原生型(wild type)，需再加上接受過抗表皮生長因子受體（anti-EGFR）療法。"



//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
//條件1
define "2規則1-1=每次申請事前審查之療程以8週為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01EX05, 56)

//條件2
define "2規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用":
  exists (
    [MedicationRequest] MRPlan
     where MRPlan.intent = 'plan'
     and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01EX05
      )
  and exists (
    [DiagnosticReport] Report
     where exists (
      Report.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.CetuximabRegorafenibImageReportCode
      )
      and Report.effective is not null
      and FHIRHelpers.ToDateTime(Report.effective) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(Report.effective) <= "本次申請起始日期"
      )
    )

define "主要規定二":
  Reusable."續用申請" and
  "2規則1-1=每次申請事前審查之療程以8週為限"
  and "2規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

define "主要規定三":
  "2規則1-1=每次申請事前審查之療程以8週為限"


//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Regorafenib申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01EX05)

define "影像報告資料存在":
  Reusable."影像或檢查報告資料存在"

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

define "先前化療資料存在":
  Reusable."HasMedicationRecord"(CodeConcept."FluoropyrimidineBase")
  or Reusable."HasMedicationRecord"(CodeConcept.L01XA03)
  or Reusable."HasMedicationRecord"(CodeConcept.L01CE02)

define "AntiVEGF療法資料存在":
  Reusable."HasMedicationRecord"(CodeConcept.AntiVEGF)

define "KRAS檢測資料存在":
  Reusable."RAS基因檢測資料存在"

define "AntiEGFR療法資料存在":
  Reusable."AntiEGFR療法資料存在"

define "續用客觀證據資料存在":
  Reusable."影像或檢查報告資料存在"

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01EX05)

define "必要資料皆存在":
  not (
    (Reusable."初次申請" and (
      not "Regorafenib申請資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "癌症分期資料存在"
      or not "影像報告資料存在"
      or not "先前化療資料存在"
      or not "AntiVEGF療法資料存在"
      or ("KRAS檢測資料存在" and "1規則3-1=K-ras為原生型(wild type)" and not "AntiEGFR療法資料存在")
    ))
    or (Reusable."續用申請" and (
      not "Regorafenib申請資料存在"
      or not "續用客觀證據資料存在"
    ))
    or not "療程期間資料存在"
  )


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" or "1規則1-2=癌症分期分數或結果為M≠1" or "1規則1-3=三個月內有影像檢查報告" or "1規則2-1-1=曾接受fluoropyrimidine為基礎的化療" or "1規則2-1-2=曾接受oxaliplatin為基礎的化療" or "1規則2-1-3=曾接受irinotecan為基礎的化療" or "1規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法" or "1規則3-1=K-ras為原生型(wild type)" or "1規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法")
    then '<主要規定一：初次使用條件>\n' +
         (if Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '● 規則1-1：主要疾病之ICD代碼為C18、C19、C20、C21\n' else '') +
         (if "1規則1-2=癌症分期分數或結果為M≠1" 
           then '● 規則1-2：癌症分期分數或結果為M≠1\n' else '') +
         (if "1規則1-3=三個月內有影像檢查報告"
           then '● 規則1-3：三個月內有影像檢查報告\n' else '') +
         (if "1規則2-1-1=曾接受fluoropyrimidine為基礎的化療"
           then '● 規則2-1-1：曾接受fluoropyrimidine為基礎的化療\n' else '') +
         (if "1規則2-1-2=曾接受oxaliplatin為基礎的化療"
           then '● 規則2-1-2：曾接受oxaliplatin為基礎的化療\n' else '') +
         (if "1規則2-1-3=曾接受irinotecan為基礎的化療"
           then '● 規則2-1-3：曾接受irinotecan為基礎的化療\n' else '') +
         (if "1規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法" 
           then '● 規則2-2：曾接受抗血管內皮生長因子（anti-VEGF）等療法\n' else '') +
         (if "1規則3-1=K-ras為原生型(wild type)" and "1規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法"
           then '● 規則3：K-ras為原生型且已接受抗表皮生長因子受體（anti-EGFR）療法\n' 
           else if not "1規則3-1=K-ras為原生型(wild type)"
           then '● 規則3：K-ras非原生型，無需接受anti-EGFR療法\n'
           else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and ("2規則1-1=每次申請事前審查之療程以8週為限" or "2規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用")
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "2規則1-1=每次申請事前審查之療程以8週為限"
           then '● 續用規則1-1：每次申請事前審查之療程以8週為限（參考資訊）\n' else '') +
         (if "2規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
           then '● 續用規則1-2：提出客觀證據（如：影像學）證實無惡化\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "2規則1-1=每次申請事前審查之療程以8週為限"
    then '<主要規定三：藥品使用規則>\n' +
         '● 規則3-1：每次申請事前審查之療程以8週為限（參考資訊）\n'
    else '')

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
      (Reusable."主要疾病ICD診斷資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21") or 
      ("癌症分期資料存在" and not "1規則1-2=癌症分期分數或結果為M≠1") or 
      ("影像報告資料存在" and not "1規則1-3=三個月內有影像檢查報告") or
      ("先前化療資料存在" and not "1規則2-1=曾接受fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療") or
      ("AntiVEGF療法資料存在" and not "1規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法") or
      ("KRAS檢測資料存在" and "1規則3-1=K-ras為原生型(wild type)" and "AntiEGFR療法資料存在" and not "1規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if Reusable."主要疾病ICD診斷資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
          then '▲ 規則1-1：主要疾病之ICD代碼未使用C18、C19、C20、C21\n' else '') +
         (if "癌症分期資料存在" and not "1規則1-2=癌症分期分數或結果為M≠1" 
          then '▲ 規則1-2：癌症分期分數或結果不為M≠1\n' else '') +
         (if "影像報告資料存在" and not "1規則1-3=三個月內有影像檢查報告"
          then '▲ 規則1-3：影像檢查報告不在三個月內或代碼不符合\n' else '') +
         (if "先前化療資料存在" and not "1規則2-1=曾接受fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療"
          then '▲ 規則2-1：先前化療資料未完整符合fluoropyrimidine、oxaliplatin、irinotecan條件\n' else '') +
         (if "AntiVEGF療法資料存在" and not "1規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法"
          then '▲ 規則2-2：先前用藥資料不符合anti-VEGF療法條件\n' else '') +
         (if "KRAS檢測資料存在" and "1規則3-1=K-ras為原生型(wild type)" and "AntiEGFR療法資料存在" and not "1規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法"
          then '▲ 規則3-2：未接受抗表皮生長因子受體（anti-EGFR）療法\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if "療程期間資料存在" and not "2規則1-1=每次申請事前審查之療程以8週為限"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1：每次申請事前審查之療程超過8週上限（參考資訊）\n'
    else '')

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
      not "Regorafenib申請資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "癌症分期資料存在"
      or not "影像報告資料存在"
      or not "先前化療資料存在"
      or not "AntiVEGF療法資料存在"
      or not "KRAS檢測資料存在"
      or ("1規則3-1=K-ras為原生型(wild type)" and not "AntiEGFR療法資料存在")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Regorafenib申請資料存在"
           then '▲ 申請醫令：未提供Regorafenib申請醫令資料\n' else '') +
         (if not Reusable."主要疾病ICD診斷資料存在"
           then '▲ 規則1-1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "癌症分期資料存在"
           then '▲ 規則1-2：未提供癌症分期分數或結果資料\n' else '') +
         (if not "影像報告資料存在"
           then '▲ 規則1-3：未提供三個月內影像檢查報告\n' else '') +
         (if not "先前化療資料存在"
           then '▲ 規則2-1：未提供完整的化療用藥資料\n' +
                (if not "1規則2-1-1=曾接受fluoropyrimidine為基礎的化療"
                  then '  - 未提供fluoropyrimidine為基礎的化療用藥資料\n' else '') +
                (if not "1規則2-1-2=曾接受oxaliplatin為基礎的化療"
                  then '  - 未提供oxaliplatin為基礎的化療用藥資料\n' else '') +
                (if not "1規則2-1-3=曾接受irinotecan為基礎的化療"
                  then '  - 未提供irinotecan為基礎的化療用藥資料\n' else '')
           else '') +
         (if not "AntiVEGF療法資料存在"
           then '▲ 規則2-2：未提供抗血管內皮生長因子（anti-VEGF）等療法用藥資料\n' else '') +
         (if not "KRAS檢測資料存在"
           then '▲ 規則3-1：未提供K-ras檢測資料\n' else '') +
         (if "1規則3-1=K-ras為原生型(wild type)" and not "AntiEGFR療法資料存在"
           then '▲ 規則3-2：K-ras為原生型，未提供anti-EGFR療法用藥資料\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (not "Regorafenib申請資料存在" or not "續用客觀證據資料存在")
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "Regorafenib申請資料存在" then '▲ 申請醫令：未提供Regorafenib申請醫令資料\n' else '') +
         (if not "續用客觀證據資料存在" then '▲ 續用規則1-2：未提供客觀證據（如：影像學）\n' else '') +
         '\n'  
    else '') +

  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1：未提供療程起迄日期資料（參考資訊）\n' +
         '\n'
    else '') 


//============================================
// 審核結果
//============================================

define "大腸直腸癌Regorafenib申請結果_布林":
  case
    when Reusable."初次申請" then (
      "1規則1=轉移性大腸直腸癌（mCRC）" and
      "1規則2=用於治療先前曾接受下列療法的轉移性大腸直腸癌（mCRC）患者，療法包括fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療，和抗血管內皮生長因子(anti-VEGF)等療法；" and
      "1規則3=若K-ras為原生型(wild type)，需再加上接受過抗表皮生長因子受體（anti-EGFR）療法。"
    )
    when Reusable."續用申請" then (
      "2規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
    )
    else false
  end


define "大腸直腸癌Regorafenib申請結果":
  if (
    Reusable."初次申請" and 
    "1規則1=轉移性大腸直腸癌（mCRC）" and
    "1規則2=用於治療先前曾接受下列療法的轉移性大腸直腸癌（mCRC）患者，療法包括fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療，和抗血管內皮生長因子(anti-VEGF)等療法；" and
    "1規則3=若K-ras為原生型(wild type)，需再加上接受過抗表皮生長因子受體（anti-EGFR）療法。"
  )
  then '✓通過：初次使用－大腸直腸癌 Regorafenib 用藥申請'
  else if (
    Reusable."續用申請" and
    "2規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
  )
  then '✓通過：續用－大腸直腸癌 Regorafenib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－大腸直腸癌 Regorafenib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－大腸直腸癌 Regorafenib 用藥申請'
  else '✖不通過：無法判定申請類型－大腸直腸癌 Regorafenib 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 大腸直腸癌之Regorafenib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Regorafenib申請結果" +
  '\n===============================================\n'
