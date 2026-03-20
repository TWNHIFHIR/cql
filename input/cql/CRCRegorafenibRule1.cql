//大腸直腸_CRCRegorafenib給付規定
library CRCRegorafenibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include CRCCodeConcept version '1.0.0' called CodeConcept

include CRCReusable version '1.0.0' called Reusable
 
context Patient

//============================================
// 申請類型判斷
//============================================

define "初次申請":
  "申請類型" = '初次使用'

define "續用申請":
  "申請類型" = '續用'

define "申請類型未知":
  "申請類型" = '無法判斷申請類型'

define "申請類型":
  case
    when Reusable."續用註記為1" then '初次使用'
    when Reusable."續用註記為2" then '續用'
    else '無法判斷申請類型'
  end


//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1
//Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
define "ICD代碼檢核_布林值": Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

//條件2
define "規則1-2=癌症分期分數或結果為M≠1":
  Count(
    [Observation] O
    where exists (
      O.code.coding Cdg
      where Cdg.code = '399390009'
        and Cdg in CodeConcept.SNOMED
    )
    and O.value is not null
    and O.value is FHIR.string
    and Matches((O.value as FHIR.string).value, '.*M[^1].*')
  ) > 0

//條件3
define "規則1-3=三個月內有影像檢查報告":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.CetuximabRegorafenibImageReportCode
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= Today() - 90 days
    and FHIRHelpers.ToDateTime(O.effective) <= Today()
  )

define "規則1=轉移性大腸直腸癌（mCRC）":
  Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
  and "規則1-2=癌症分期分數或結果為M≠1"
  and "規則1-3=三個月內有影像檢查報告"

/*規則2*/
//條件1
define "規則2-1=曾接受fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療":
  (
    // 存在 Fluoropyrimidine 處方且治療期間已結束
    exists (
     [MedicationRequest] MROrder1
        where MROrder1.intent = 'order'
        and exists (
        MROrder1.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01BC02
        or Cdg.code in CodeConcept.L01BC03
        or Cdg.code in CodeConcept.L01BC53
        or Cdg.code in CodeConcept.L01BC06
        or Cdg.code in CodeConcept.L01CE02
        or Cdg.code in CodeConcept.L01XA03
     )
    and Reusable."HasValidTiming"(MROrder1)
    and Reusable."GetEndTime"(MROrder1) < Today()
     )
    and
    // 存在 Oxaliplatin 處方且治療期間已結束
    exists (
     [MedicationRequest] MROrder2
    where MROrder2.intent = 'order'
    and exists (
    MROrder2.medication.coding Cdg
    where Cdg in CodeConcept.NHIMedication
    and Cdg.code in CodeConcept.L01XA03
     )
    and Reusable."HasValidTiming"(MROrder2)
    and Reusable."GetEndTime"(MROrder2) < Today()
     )
    and
    // 存在 Irinotecan 處方且治療期間已結束
    exists (
     [MedicationRequest] MROrder3
    where MROrder3.intent = 'order'
    and exists (
    MROrder3.medication.coding Cdg
    where Cdg in CodeConcept.NHIMedication
    and Cdg.code in CodeConcept.L01CE02
     )
    and Reusable."HasValidTiming"(MROrder3)
    and Reusable."GetEndTime"(MROrder3) < Today()
     )
  )

//條件2
define "規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法":
  (
    // 存在 antiVEGF 處方且治療期間已結束
    exists (
     [MedicationRequest] MROrder1
    where MROrder1.intent = 'order'
    and exists (
    MROrder1.medication.coding Cdg
    where Cdg in CodeConcept.NHIMedication
    and Cdg.code in CodeConcept.L01FG
     )
    and Reusable."HasValidTiming"(MROrder1)
    and Reusable."GetEndTime"(MROrder1) < Today()
     )
  )

define "規則2=用於治療先前曾接受下列療法的轉移性大腸直腸癌（mCRC）患者，療法包括fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療，和抗血管內皮生長因子(anti-VEGF)等療法；":
  "規則2-1=曾接受fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療"
  and "規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法"

/*規則3*/
//條件1
define "規則3-1=K-ras為原生型(wild type)":
  exists (
    [Observation] RasObs
    where RasObs.status = 'final'
    and exists (
      RasObs.code.coding Cdg
      where Cdg.code = '69548-6'
      and Cdg in CodeConcept.LOINC
    )
    and exists (
      RasObs.component C
      where exists (
        C.code.coding Cdg
        where Cdg.code in CodeConcept.GeneTest
      )
    )
    and exists (
      RasObs.interpretation.coding I
      where I.code = 'NEG'
    )
  )

//條件2
define "規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法":
  (
    exists (
     [MedicationRequest] MROrder1
    where MROrder1.intent = 'order'
    and exists (
    MROrder1.medication.coding Cdg
    where Cdg in CodeConcept.NHIMedication
    and Cdg.code in CodeConcept.L01FG
     )
    and Reusable."HasValidTiming"(MROrder1)
    and Reusable."GetEndTime"(MROrder1) < Today()
     )
  )

define "規則3=若K-ras為原生型(wild type)，需再加上接受過抗表皮生長因子受體（anti-EGFR）療法。":
  "規則3-1=K-ras為原生型(wild type)"
  and "規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法"


define "主要規定一":
  "初次申請" and
  "規則1=轉移性大腸直腸癌（mCRC）"
  and "規則2=用於治療先前曾接受下列療法的轉移性大腸直腸癌（mCRC）患者，療法包括fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療，和抗血管內皮生長因子(anti-VEGF)等療法；"
  and "規則3=若K-ras為原生型(wild type)，需再加上接受過抗表皮生長因子受體（anti-EGFR）療法。"



//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
//條件1
define "規則1-1=每次申請事前審查之療程以8週為限":
  exists [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
    and exists (
      MRPlan.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01EX05
    )
    and days between
      start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)
      and
      end of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)
      <= 56 

//條件2
define "規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用":
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
      and FHIRHelpers.ToDateTime(Report.effective) >= Today() - 90 days
      and FHIRHelpers.ToDateTime(Report.effective) <= Today()
      )
    )

define "主要規定二":
  "續用申請" and
  "規則1-1=每次申請事前審查之療程以8週為限"
  and "規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

define "主要規定三":
  "規則1-1=每次申請事前審查之療程以8週為限"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if "初次申請" and (Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" or "規則1-2=癌症分期分數或結果為M≠1" or "規則1-3=三個月內有影像檢查報告" or "規則2-1=曾接受fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療" or "規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法" or "規則3-1=K-ras為原生型(wild type)" or "規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法")
    then '<主要規定一：初次使用條件>\n' +
         (if Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '● 規則1-1：主要疾病之ICD代碼為C18、C19、C20、C21\n' else '') +
         (if "規則1-2=癌症分期分數或結果為M≠1" 
           then '● 規則1-2：癌症分期為轉移性（M≠0）\n' else '') +
         (if "規則1-3=三個月內有影像檢查報告"
           then '● 規則1-3：三個月內有影像檢查報告\n' else '') +
         (if "規則2-1=曾接受fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療" 
           then '● 規則2-1：曾接受fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療\n' else '') +
         (if "規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法" 
           then '● 規則2-2：曾接受抗血管內皮生長因子（anti-VEGF）等療法\n' else '') +
         (if "規則3-1=K-ras為原生型(wild type)" and "規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法"
           then '● 規則3：K-ras為原生型且已接受抗表皮生長因子受體（anti-EGFR）療法\n' 
           else if not "規則3-1=K-ras為原生型(wild type)"
           then '● 規則3：K-ras非原生型，無需接受anti-EGFR療法\n'
           else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if "續用申請" and ("規則1-1=每次申請事前審查之療程以8週為限" or "規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用")
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "規則1-1=每次申請事前審查之療程以8週為限"
           then '● 續用規則1-1：每次申請事前審查之療程以8週為限\n' else '') +
         (if "規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
           then '● 續用規則1-2：提出客觀證據（如：影像學）證實無惡化\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "規則1-1=每次申請事前審查之療程以8週為限"
    then '<主要規定三：藥品使用規則>\n' +
         '● 規則3-1：每次申請事前審查之療程以8週為限\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if "初次申請" and (
      not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" or 
      not "規則1-2=癌症分期分數或結果為M≠1" or 
      "規則3-1=K-ras為原生型(wild type)" or 
      not "規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法"
    )
    then '<主要規定一：初次使用條件>\n' +
         (if not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
          then '▲ 規則1-1：主要疾病之ICD代碼未使用C18、C19、C20、C21\n' else '') +
         (if not "規則1-2=癌症分期分數或結果為M≠1" 
          then '▲ 規則1-2：癌症分期分數或結果不為M≠0\n' else '') +
         (if "規則3-1=K-ras為原生型(wild type)"
          then '▲ 規則3-1：K-ras為原生型(wild type)\n' else '') +
         (if not "規則3-2=需再加上接受過抗表皮生長因子受體(anti-EGFR)療法"
          then '▲ 規則3-2：未接受抗表皮生長因子受體（anti-EGFR）療法\n' else '') +
         '\n'  
    else ''
  ) +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "規則1-1=每次申請事前審查之療程以8週為限"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1：每次申請事前審查之療程超過8週上限\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if "初次申請" and (not "規則1-3=三個月內有影像檢查報告" or not "規則2-1=曾接受fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療" or not "規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法")
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則1-3=三個月內有影像檢查報告"
           then '▲ 規則1-3：未提供三個月內影像檢查報告\n' else '') +
         (if not "規則2-1=曾接受fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療"
           then '▲ 規則2-1：未提供fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療用藥資料\n' else '') +
         (if not "規則2-2=曾接受抗血管內皮生長因子(anti-VEGF)等療法"
           then '▲ 規則2-2：未提供抗血管內皮生長因子（anti-VEGF）等療法用藥資料\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if "續用申請" and not "規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則1-2：未提供客觀證據（如：影像學）\n' +
         '\n'  
    else '')

//============================================
// 審核結果
//============================================

define "大腸直腸癌Regorafenib申請結果_布林":
  case
    when "初次申請" then (
      "規則1=轉移性大腸直腸癌（mCRC）" and
      "規則2=用於治療先前曾接受下列療法的轉移性大腸直腸癌（mCRC）患者，療法包括fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療，和抗血管內皮生長因子(anti-VEGF)等療法；" and
      "規則3=若K-ras為原生型(wild type)，需再加上接受過抗表皮生長因子受體（anti-EGFR）療法。" and
      "規則1-1=每次申請事前審查之療程以8週為限"
    )
    when "續用申請" then (
      "規則1-1=每次申請事前審查之療程以8週為限" and
      "規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
    )
    else false
  end


define "大腸直腸癌Regorafenib申請結果":
  if (
    "初次申請" and 
    "規則1=轉移性大腸直腸癌（mCRC）" and
    "規則2=用於治療先前曾接受下列療法的轉移性大腸直腸癌（mCRC）患者，療法包括fluoropyrimidine、oxaliplatin、irinotecan為基礎的化療，和抗血管內皮生長因子(anti-VEGF)等療法；" and
    "規則3=若K-ras為原生型(wild type)，需再加上接受過抗表皮生長因子受體（anti-EGFR）療法。" and
    "規則1-1=每次申請事前審查之療程以8週為限"
  )
  then '✓通過：初次使用－大腸直腸癌 Regorafenib 用藥申請'
  else if (
    "續用申請" and
    "規則1-1=每次申請事前審查之療程以8週為限" and
    "規則1-2=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
  )
  then '✓通過：續用－大腸直腸癌 Regorafenib 用藥申請'
  else if "初次申請"
  then '✖不通過：初次使用－大腸直腸癌 Regorafenib 用藥申請'
  else if "續用申請"
  then '✖不通過：續用－大腸直腸癌 Regorafenib 用藥申請'
  else '✖不通過：無法判定申請類型－大腸直腸癌 Regorafenib 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 大腸直腸癌之Regorafenib 申請審核報告 ===\n' +
  '\n【申請類型】' + "申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Regorafenib申請結果" +
  '\n===============================================\n'